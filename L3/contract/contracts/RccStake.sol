// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract RCCStake is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
  using SafeERC20 for IERC20;
  using Address for address;
  using Math for uint256;

  bytes32 public constant ADMIN_ROLE = keccak256("admin_role");
  bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role");
  uint256 public constant ETH_PID = 0;

  struct Pool {
    address stTokenAddress;
    uint256 poolWeight;
    uint256 lastRewardBlock;
    uint256 accRCCPerST;
    uint256 stTokenAmount;
    uint256 minDepositAmount;
    uint256 unstakeLockedBlocks;
  }

  struct UnstakeRequest {
    uint256 amount;
    uint256 unlockBlocks;
  }

  struct User {
    uint256 stAmount;
    uint256 finishedRCC;
    uint256 pendingRCC;
    UnstakeRequest[] requests;
  }

 // ********* STATE VARIABLES *********
  uint256 public startBlock;
  uint256 public endBlock;
  uint256 public rccPerBlock;
  bool public withdrawPaused;
  bool public claimPaused;

  IERC20 public RCC;
  uint256 public totalPoolWeight;
  Pool[] public pool;

  mapping(uint256 => mapping(address => User)) public users;

  // ********* EVENTS *********
  event SetRCC(IERC20 indexed RCC);

  event PauseWithdraw();

  event UnpauseWithdraw();

  event PauseClaim();

  event UnpauseClaim();

  event SetStartBlock(uint256 indexed startBlock);

  event SetEndBlock(uint256 indexed endBlock);

  event SetRccPerBlock(uint256 indexed rccPerBlock);

  event AddPool(address indexed stTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardBlock, uint256 minDepositAmount, uint256 unstakeLockedBlocks);

  event UpdatePoolInfo(uint256 indexed poolId, uint256 indexed minDepositAmount, uint256 indexed unstakeLockedBlocks);

  event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight);

  event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardBlock, uint256 totalRCC);

  event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);

  event RequestUnstake(address indexed user, uint256 indexed poolId, uint256 amount);

  event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount, uint256 indexed blockNumber);

  event Claim(address indexed user, uint256 indexed poolId, uint256 rccReward);

  // ********* MODIFIERS *********
  modifier checkPid(uint256 _pid) {
    require(_pid < pool.length, "Invalid pool id");
    _;
  }

  modifier whenNotClaimPaused() {
    require(!claimPaused, "Claim is paused");
    _;
  }

  modifier whenNotWithdrawPaused() {
    require(!withdrawPaused, "Withdraw is paused");
    _;
  }

  function initialize(
    IERC20 _RCC,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rccPerBlock
  ) public initializer {
    require(_startBlock <= _endBlock && _rccPerBlock > 0, "Invalid parameters");

    __AccessControl_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(ADMIN_ROLE, msg.sender);
    _grantRole(UPGRADE_ROLE, msg.sender);

    setRCC(_RCC);
    startBlock = _startBlock;
    endBlock = _endBlock;
    rccPerBlock = _rccPerBlock;
  }

function _authorizeUpgrade(address newImplementation)
	internal
	onlyRole(UPGRADE_ROLE)
	override
{

}

  function setRCC(IERC20 _RCC) public onlyRole(ADMIN_ROLE) {
    RCC = _RCC;

    emit SetRCC(_RCC);
  }

  function pauseWithdraw() public onlyRole(ADMIN_ROLE) {
    require(!withdrawPaused, "withdraw has been already paused");

    withdrawPaused = true;

    emit PauseWithdraw();
  }

  function unpauseWithdraw() public onlyRole(ADMIN_ROLE) {
    require(withdrawPaused, "withdraw has been already unpaused");

    withdrawPaused = false;

    emit UnpauseWithdraw();
  }

  function pasueClaim() public onlyRole(ADMIN_ROLE) {
    require(!claimPaused, "claim has been already paused");

    claimPaused = true;

    emit PauseClaim();
  }

  function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
    require(_startBlock <= endBlock, "Start block must be less than end block");

    startBlock = _startBlock;

    emit SetStartBlock(_startBlock);
  }

  function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
	require(startBlock <= _endBlock, "start block must be smaller than end block");

	endBlock = _endBlock;

	emit SetEndBlock(_endBlock);
  }

  function setRCCPerBlock(uint256 _rccPerBlock) public onlyRole(ADMIN_ROLE) {
    require(_rccPerBlock > 0, "invalid parameter");

    rccPerBlock = _rccPerBlock;

    emit SetRccPerBlock(_rccPerBlock);
  }
 
  function addPool(address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks, bool _withUpdate) public onlyRole(ADMIN_ROLE) {
    if(pool.length > 0) {
      require(_stTokenAddress != address(0x0), "Invalid stake token address");
    } else {
      require(_stTokenAddress == address(0x0), "Invalid stake token address");
    }

    if(_withUpdate) {
      massUpdatePools();
    }

    uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
    totalPoolWeight += _poolWeight;

    pool.push(Pool({
      stTokenAddress: _stTokenAddress,
      poolWeight: _poolWeight,
      lastRewardBlock: lastRewardBlock,
      accRCCPerST: 0,
      stTokenAmount: 0,
      minDepositAmount: _minDepositAmount,
      unstakeLockedBlocks: _unstakeLockedBlocks
    }));

    emit AddPool(_stTokenAddress, _poolWeight, lastRewardBlock, _minDepositAmount, _unstakeLockedBlocks);

  }

  function massUpdatePools() public {
    uint256 length = pool.length;
    for (uint256 pid = 0; pid < length; pid++) {
      updatePool(pid);
    }
  }

  function updatePool(uint256 _pid) public checkPid(_pid) {
    Pool storage pool_ = pool[_pid];

    if(block.number <= pool_.lastRewardBlock) {
      return;
    }

    (bool success1, uint256 totalRCC) = getMultiplier(pool_.lastRewardBlock, block.number).tryMul(pool_.poolWeight);
    require(success1, "overflow");

    uint256 stSupply = pool_.stTokenAmount;
    if(stSupply > 0) {
      (bool success2, uint256 totalRCC_) = totalRCC.tryMul(1 ether);
      require(success2, "overflow");

      (success2, totalRCC_) = totalRCC_.tryDiv(stSupply);
      require(success2, "overflow");

      (bool success3, uint256 accRCCPerST) = pool_.accRCCPerST.tryAdd(totalRCC_);
      require(success3, "overflow");
      pool_.accRCCPerST = accRCCPerST;
    }

    pool_.lastRewardBlock = block.number;

    emit UpdatePool(_pid, pool_.lastRewardBlock, totalRCC);
  }

  function depositETH() public whenNotPaused() payable {
    Pool storage pool_ = pool[ETH_PID];
    require(pool_.stTokenAddress == address(0x0), "Invalid staking token address");

    uint256 amount_ = msg.value;
    require(amount_ >= pool_.minDepositAmount, "Deposit amount is too small");

    _deposit(ETH_PID, amount_);
  }

  function deposit(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) {
	require(_pid != 0, "Deposit not supported ETH staking");
	Pool storage pool_ = pool[_pid];
	require(_amount > pool_.minDepositAmount, "Deposit amount is too small");

	if(_amount > 0) {
		IERC20(pool_.stTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
	}

	_deposit(_pid, _amount);
  }

  function unstake(uint256 _pid, uint256 _amount) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused() {
	Pool storage pool_ = pool[_pid];
	User storage user_ = users[_pid][msg.sender];

	require(user_.stAmount >= _amount, "Not enough staked amount");

	updatePool(_pid);

	uint256 pendingRCC_ = user_.stAmount * pool_.accRCCPerST / (1 ether) - user_.finishedRCC;

	if(pendingRCC_ > 0) {
		user_.pendingRCC = user_.pendingRCC + pendingRCC_;
	}

	if(_amount > 0) {
		user_.stAmount = user_.stAmount - _amount;
		user_.requests.push(
			UnstakeRequest({
				amount: _amount,
				unlockBlocks: block.number + pool_.unstakeLockedBlocks
			})
		);
	}

	pool_.stTokenAmount = pool_.stTokenAmount - _amount;
	user_.finishedRCC = user_.stAmount * pool_.accRCCPerST / (1 ether);

	emit RequestUnstake(msg.sender, _pid, _amount);
  }

  function withdraw(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotWithdrawPaused {
	Pool storage pool_ = pool[_pid];
	User storage user_ = users[_pid][msg.sender];

	uint256 pendingWithdraw_;
	uint256 popNum_;
	for(uint256 i = 0; i < user_.requests.length; i++) {
		if(user_.requests[i].unlockBlocks > block.number) {
			break;
		}
		pendingWithdraw_ = pendingWithdraw_ + user_.requests[i].amount;
		popNum_++;
	}

	for(uint256 i = 0; i < user_.requests.length - popNum_; i++) {
		user_.requests[i] = user_.requests[i + popNum_];
	}

	for(uint256 i = 0; i < popNum_; i++) {
		user_.requests.pop();
	}

	if(pendingWithdraw_ > 0) {
		if(pool_.stTokenAddress == address(0x0)) {
			_safeETHTransfer(msg.sender, pendingWithdraw_);
		} else {
			IERC20(pool_.stTokenAddress).safeTransfer(msg.sender, pendingWithdraw_);
		}
	}

	emit Withdraw(msg.sender, _pid, pendingWithdraw_, block.number);
  }

  function claim(uint256 _pid) public whenNotPaused() checkPid(_pid) whenNotClaimPaused{ 
	Pool storage pool_ = pool[_pid];
	User storage user_ = users[_pid][msg.sender];

	updatePool(_pid);

	uint256 peddingRCC_ = user_.stAmount * pool_.accRCCPerST / (1 ether) - user_.finishedRCC + user_.pendingRCC;
  
	if(peddingRCC_ > 0) {
		user_.pendingRCC = 0;
		_safeRCCTransfer(msg.sender, peddingRCC_);
	}

	user_.finishedRCC = user_.stAmount * pool_.accRCCPerST / (1 ether);

	emit Claim(msg.sender, _pid, peddingRCC_);
  }

  function _deposit(uint256 _pid, uint256 _amount) internal {
    Pool storage pool_ = pool[_pid];
	User storage user_ = users[_pid][msg.sender];

	updatePool(_pid);

	if(user_.stAmount > 0) {
		(bool success1, uint256 accST) = user_.stAmount.tryMul(pool_.accRCCPerST);
		require(success1, "User stAmount mul accRCCPerST overflow");
		(success1, accST) = accST.tryDiv(1 ether);
		require(success1, "accST div 1 ether overflow");

		(bool success2, uint256 pendingRCC_) = accST.trySub(user_.finishedRCC);
		require(success2, "accST sub finishedRCC overflow");

		if(pendingRCC_ > 0) {
			(bool success3, uint256 _pendingRCC) = user_.pendingRCC.tryAdd(pendingRCC_);
			require(success3, "User pendingRCC overflow");
			user_.pendingRCC = _pendingRCC;
		}
	}

	if(_amount > 0) {
		(bool success4, uint256 stAmount) = user_.stAmount.tryAdd(_amount);
		require(success4, "User stAmount overflow");
		user_.stAmount = stAmount;
	}

	(bool success5, uint256 stTokenAmount) = pool_.stTokenAmount.tryAdd(_amount);
	require(success5, "Pool stTokenAmount overflow");
	pool_.stTokenAmount = stTokenAmount;

	(bool success6, uint256 finishedRCC) = user_.stAmount.tryMul(pool_.accRCCPerST);
	require(success6, "User stAmount mul accRCCPerST overflow");

	(success6, finishedRCC) = finishedRCC.tryDiv(1 ether);
	require(success6, "finishedRCC div 1 ether overflow");

	user_.finishedRCC = finishedRCC;

	emit Deposit(msg.sender, _pid, _amount);
  }

  function _safeRCCTransfer(address _to, uint256 _amount) internal {
	uint256 RCCBal = RCC.balanceOf(address(this));

	if(_amount > RCCBal) {
		RCC.transfer(_to, RCCBal);
	} else {
		RCC.transfer(_to, _amount);
	}
  }

  function _safeETHTransfer(address _to, uint256 _amount) internal {
	(bool success, bytes memory data) = address(_to).call{
		value: _amount
	}("");

	require(success, "ETH transfer failed");
	if(data.length > 0) {
		require(
			abi.decode(data, (bool)),
			"ETH transfer operation did not succeed"
		);
	}
  }

  function setPoolWeight(uint256 _pid, uint256 _poolWeight, bool _withUpdate) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
    require(_poolWeight > 0, "Invalid pool weight");

    if(_withUpdate) {
      massUpdatePools();
    }

    totalPoolWeight = totalPoolWeight - pool[_pid].poolWeight + _poolWeight;
    pool[_pid].poolWeight = _poolWeight;

    emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
  }

  function poolLength() external view returns(uint256) {
    return pool.length;
  }

  function getMultiplier(uint256 _from, uint256 _to) public view returns(uint256 multiplier) {
    require(_from < _to, "Invalid block");
    if(_from < startBlock) {_from = startBlock;}
    if(_to > endBlock) {_to = endBlock;}
    require(_from <= _to, "End block must be greater than start block");
    bool success;
    (success, multiplier) = (_to - _from).tryMul(rccPerBlock);
    require(success, "Multiplier overflow");
  }

  function pendingRCC(uint256 _pid, address _user) external checkPid(_pid) view returns(uint256) {
    return pendingRCCByBlockNumber(_pid, _user, block.number);
  }

  function pendingRCCByBlockNumber(uint256 _pid, address _user, uint256 _blockNumber) public checkPid(_pid) view returns(uint256) {
    Pool storage pool_ = pool[_pid];
    User storage user_ = users[_pid][_user];
    uint256 accRCCPerST = pool_.accRCCPerST;
    uint256 stSupply = pool_.stTokenAmount;

    if(_blockNumber > pool_.lastRewardBlock && stSupply != 0) {
        uint256 multiplier = getMultiplier(pool_.lastRewardBlock, _blockNumber);
        uint256 rccForPool = multiplier * pool_.poolWeight / totalPoolWeight;
        accRCCPerST = accRCCPerST + rccForPool * (1 ether) / stSupply;
    }

    return user_.stAmount * accRCCPerST / (1 ether) - user_.finishedRCC + user_.pendingRCC;
  }

  function stakingBalance(uint256 _pid, address _user) external checkPid(_pid) view returns(uint256) {
    return users[_pid][_user].stAmount;
  }

  function withdrawAmount(uint256 _pid, address _user) public checkPid(_pid) view returns(uint256 requestAmount, uint256 pendingWithdrawAmount) {
    User storage user_ = users[_pid][_user];

    for(uint256 i = 0; i < user_.requests.length; i++) {
        if(user_.requests[i].unlockBlocks <= block.number) {
            pendingWithdrawAmount = pendingWithdrawAmount + user_.requests[i].amount;
        }
        requestAmount = requestAmount + user_.requests[i].amount;
    }
  }




}