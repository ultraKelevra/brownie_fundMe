// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    address[] public funders;
    mapping(address => uint256) public address2Founds;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        require(
            getConvertedPrice(msg.value) >= getEntranceFee(),
            "YOU HAVE TO GIVE ME MORE MONEY PEASANT!"
        );
        address2Founds[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * (10**18);
        uint256 price = getPrice();
        uint256 precision = 1 * (10**18);
        return (minimumUSD * precision) / price;
    }

    function getConvertedPrice(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 usdAmount = (ethAmount * ethPrice) / 1000000000000000000;
        return usdAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        require(msg.sender == owner, "only the owner can withdraw eth!");
        msg.sender.transfer(address(this).balance);

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            address2Founds[funder] = 0;
        }

        funders = new address[](0);
    }
}
