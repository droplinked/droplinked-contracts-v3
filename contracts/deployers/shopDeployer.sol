// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../base/Shop.sol";
import "../tokens/erc1155.sol";

contract DropShopDeployer is Ownable {
    event ShopDeployed(address shop, address nftContract);

    address[] public shopAddresses;
    address[] public nftContracts;
    uint256 public shopCount;

    constructor() Ownable(msg.sender) {}

    function deployShop(
        string memory _shopName,
        string memory _shopAddress,
        address _shopOwner,
        string memory _shopLogo,
        string memory _shopDescription
    ) public onlyOwner returns (address shop, address nftContract) {
        DropShop _shop = new DropShop(
            _shopName,
            _shopAddress,
            _shopOwner,
            _shopLogo,
            _shopDescription
        );
        // deploy the nft contract here
        DroplinkedToken token = new DroplinkedToken(address(this)); // TODO check this line
        nftContracts.push(address(token));
        shopAddresses.push(address(_shop));
        shopCount++;
        emit ShopDeployed(address(_shop), address(token));
        return (address(_shop), address(token));
    }
}