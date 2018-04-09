pragma solidity ^0.4.18;


contract EnglishAuction {
    
    struct Auction {
        address beneficiary;
        bytes32 assetName;
        address highestBidder;
        uint256 highestBid;
        uint256 auctionEnd;
        bool ended;
        mapping(address => uint) pendingReturns;
    }

    uint256 public creationFee;
    mapping (bytes32=>uint256) public auctionNametoIdx;
    Auction[] public auctions;

    modifier onlyBefore(uint _time) {require(now < _time); _;}
    modifier onlyAfter(uint _time) {require(now > _time); _;}

    event HighestBidIncreased(uint idx, address bidder, uint256 amount);
    event AuctionEnded(uint idx, address winner, uint256 amount);
    event AuctionCreated(uint idx, bytes32 name, address beneficiary);

    function EnglishAuction(uint _creationFee) public {
        require(_creationFee > 0);
        creationFee = _creationFee;
    }

    function createAuction(
        bytes32 _assetName,
        uint256 _biddingtime)
    public payable {
        require(msg.value >= creationFee);
        require(_biddingtime > 0);
        Auction memory newAuction;
        newAuction.assetName = _assetName;
        newAuction.auctionEnd = now + _biddingtime;
        newAuction.beneficiary = msg.sender;
        auctions.push(newAuction);
        auctionNametoIdx[_assetName] = auctions.length - 1;
        AuctionCreated(auctions.length - 1, _assetName, msg.sender);
    }

    function getAuctionCount() public view returns(uint) {
        return auctions.length;
    }

    function getTimeInfo(uint idx) public view returns(bool, uint, uint) {
        return(auctions[idx].ended, now, auctions[idx].auctionEnd);
    }

    function getPriceInfo(uint idx) public view returns(uint) {
        return(auctions[idx].highestBid);
        
    }

    function getVariables(uint idx) public view returns(
        address,
        bytes32,
        address,
        uint
    ) {
        require(idx < auctions.length);
        return (
            auctions[idx].beneficiary,
            auctions[idx].assetName,
            auctions[idx].highestBidder,
            auctions[idx].highestBid);        
    }

    function getAssetInfo(uint idx) public view returns(address, uint) {
        return (auctions[idx].highestBidder, auctions[idx].highestBid);
    }

    function bid(uint idx) public payable {
        require(now <= auctions[idx].auctionEnd);
        require(msg.value >= auctions[idx].highestBid);

        if (auctions[idx].highestBid != 0) {
            address adr = auctions[idx].highestBidder;
            // auctions[idx].pendingReturns[adr] += auctions[idx].highestBid;
            adr.transfer(auctions[idx].highestBid);
        }
        auctions[idx].highestBidder = msg.sender;
        auctions[idx].highestBid = msg.value;
        HighestBidIncreased(idx, msg.sender, msg.value);
    }

    function withdraw(uint idx) public returns(bool) {
        uint amount = auctions[idx].pendingReturns[msg.sender];
        if (amount > 0) {
            auctions[idx].pendingReturns[msg.sender] = 0;
            if (!msg.sender.send(amount)) {
                auctions[idx].pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }    

    function auctionEnd(uint idx) public {
        require(now >= auctions[idx].auctionEnd);
        require(!auctions[idx].ended);
        auctions[idx].ended = true;
        AuctionEnded(idx, auctions[idx].highestBidder, auctions[idx].highestBid);
        auctions[idx].beneficiary.transfer(auctions[idx].highestBid);
    }
}