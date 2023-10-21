// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    ERC721 public nftToken; // The NFT token contract
    uint256 public listingPrice = 0.01 ether; // Price to list an NFT

    struct Listing {
        address seller;
        uint256 tokenId;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;

    event NFTListed(address indexed seller, uint256 indexed tokenId, uint256 price);
    event NFTUnlisted(uint256 indexed tokenId);
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address _nftToken) {
        nftToken = ERC721(_nftToken);
    }

    function setListingPrice(uint256 _price) public onlyOwner {
        listingPrice = _price;
    }

    function listNFT(uint256 _tokenId, uint256 _price) public {
        require(msg.sender == nftToken.ownerOf(_tokenId), "You don't own this NFT");
        require(listings[_tokenId].active == false, "NFT is already listed");
        require(_price >= listingPrice, "Listing price is not met");
        listings[_tokenId] = Listing(msg.sender, _tokenId, _price, true);
        nftToken.transferFrom(msg.sender, address(this), _tokenId);
        emit NFTListed(msg.sender, _tokenId, _price);
    }

    function unlistNFT(uint256 _tokenId) public {
        require(listings[_tokenId].seller == msg.sender, "You don't own this listing");
        delete listings[_tokenId];
        nftToken.transferFrom(address(this), msg.sender, _tokenId);
        emit NFTUnlisted(_tokenId);
    }

    function purchaseNFT(uint256 _tokenId) public payable {
        Listing memory listing = listings[_tokenId];
        require(listing.active, "NFT is not listed for sale");
        require(msg.value >= listing.price, "Insufficient funds sent");
        delete listings[_tokenId];
        nftToken.transferFrom(address(this), msg.sender, _tokenId);
        payable(listing.seller).transfer(listing.price);
        emit NFTPurchased(msg.sender, _tokenId, listing.price);
    }
}
