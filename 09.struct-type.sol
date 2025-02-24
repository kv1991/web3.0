// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Product {
    struct ProductInfo {
        uint id;
        string name;
        uint price;
        uint stock;
    }
    mapping (uint => ProductInfo) public products;

    uint public productCount;
    function addProduct(string memory _name, uint _price, uint _stock) public {
        productCount++;
        products[productCount] = ProductInfo(productCount, _name, _price, _stock);
    }

    function updateProductStock(uint productId, uint _newStock) public {
        ProductInfo storage product = products[productId];
        product.stock = _newStock;
    }

    function getProduct(uint productId) public view returns (string memory, uint, uint) {
        ProductInfo storage product = products[productId];
        return (product.name, product.price, product.stock);
    }
}