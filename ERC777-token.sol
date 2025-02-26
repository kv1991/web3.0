import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/introspection/IERC1820Registry.sol";

contract MyERC777 is ERC777 {
    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor(
        address[] memory defaultOperators
    ) ERC777("MyToken", "MTK", defaultOperators) {
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }
}

contract OperatorContract {
    IERC1820Registry private constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256(("ERC777TokensRecipient"));

    ERC777 public token;

    constructor(ERC777 _token) {
        token = _token;
        IERC1820Registry.sertInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, address(this));
        IERC1820Registry.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external {
        require(token.isOperatorFor(msg.sender, sender), "OperatorContract: Not authorized");
        token.operatorSend(sender, recipient, amount, data, operatorData);
    }

    function tokensReceived (
        address operator,
        address from,
        address to,
        bytes calldata data,
        bytes calldata operator
    ) external {

    }
}