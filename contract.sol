// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CarLeaseSystem {
    struct Lease {
        State state;
        uint256 end_time;
    }
    
    enum State { Created, Locked, Inactive }

    address payable public seller;
    address payable public buyer;
    uint256 value;
    mapping(uint256 => Lease) private cars;

    constructor() public {
        seller = payable(msg.sender);
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");_;}
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");_;}
    modifier inState(uint256 carTokenID, State _state){
        require( cars[carTokenID].state == _state, "Invalid state");_;}


    event PurchaseConfirmed();
    event SignedBySeller();

    function confirmPurchase(uint256 carTokenID, uint256 driver_experience
        /* car token, duration, mileage, driver's experience */) public payable inState(carTokenID, State.Created){
        // if car not available for leasing, or if msg.value!=quote RAISE ERROR
        // unfinishedLease = Lease(these arguments)

        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        value = msg.value; // Locking value in contract
        cars[carTokenID].state=State.Locked;
    }

    function sellerSign(uint256 carTokenID) public onlySeller() inState(carTokenID, State.Locked){
        
        emit SignedBySeller();
        
        cars[carTokenID].state = State.Inactive;
        seller.transfer(value);
        // carNFT._transfer( ownerOf(carToken?) , msg.sender, carToken );
    }

}

contract Car is ERC721{
    uint256 original_price; // Price times 100 for int
    address public minter_address;

    constructor(uint256 _original_price) ERC721("Car","CAR"){
        minter_address = msg.sender;
    }



    //function mintCar()
}