// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CarLeaseSystem {
    struct Lease {
        State state;
        uint256 start_time;
        uint256 end_time;
        address payable buyer;
        uint256 quote;
        uint256 payments;
    }
    
    enum State { Available, Locked, Leased }

    address payable public seller;
    uint256 value;
    mapping(uint256 => Lease) private cars;
    Car private car = new Car();

    constructor( string[] memory _carURIs ) public {
        seller = payable(msg.sender);
        for (uint256 i=0; i<_carURIs.length; i++){
            cars[car.mintCAR(_carURIs[i])] = Lease(State.Available, 0,0, payable(msg.sender),0,0); // Only first argument matters
        }
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this");_;}
/*
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this");_;}
*/


    modifier inState(uint256 carTokenID, State _state){
        require( cars[carTokenID].state == _state, "Invalid state");_;}


    event PurchaseConfirmed();
    event SignedBySeller();
    event NotSignedBySeller();

    function confirmPurchase(uint256 carTokenID, uint256 current_car_mileage, uint256 driver_experience, uint256 mileage_cap, uint256 start_time, uint256 end_time
        /* car token, duration, mileage, driver's experience */) public payable inState(carTokenID, State.Available){
        uint256 price = car.calculatePrice(current_car_mileage, driver_experience, mileage_cap, end_time-start_time);
        require(msg.value==price*4, "Incorrect value sent.");

        emit PurchaseConfirmed();
        cars[carTokenID].buyer = payable(msg.sender);
        cars[carTokenID].quote = price;
        cars[carTokenID].payments = 1;
        cars[carTokenID].start_time = start_time;
        cars[carTokenID].end_time = end_time;
        value = msg.value; // Locking value in contract
        cars[carTokenID].state=State.Locked;
    }

    function sellerSign(uint256 carTokenID) public onlySeller() inState(carTokenID, State.Locked){
        
        emit SignedBySeller();
        
        cars[carTokenID].state = State.Leased;
        seller.transfer(value);
        
        car.transferOwnership( carTokenID , cars[carTokenID] );
    }

    function notSign(uint256 carTokenID) public onlySeller inState(carTokenID, State.Locked){
        emit NotSignedBySeller();
        
        cars[carTokenID].state = State.Available;
        cars[carTokenID].buyer.transfer(value);
    }

    function deleteLease(uint256 carTokenID) private onlySeller {
        cars[carTokenID].state = State.Available;
        cars[carTokenID].buyer = seller;
    }

    function insolventCustomer(uint256 carTokenID) public onlySeller inState(carTokenID, State.Leased) {
        uint256 seconds_in_a_month = 2629800;
        require ( (block.timestamp-cars[carTokenID].start_time) / seconds_in_a_month > cars[carTokenID].payments , "The customer does not currently owe anything." );
        deleteLease(carTokenID);
        car.transferOwnership(carTokenID, cars[carTokenID]);
    }

    function payMonthlyQuote(uint256 carTokenID) payable public inState(carTokenID, State.Leased) { // I dont see any reason to restrict this function to the buyer
        require(msg.value==cars[carTokenID].quote, "Incorrect value sent.");
        seller.transfer(msg.value);
        cars[carTokenID].payments = cars[carTokenID].payments + 1;
    }

}

contract Car is ERC721URIStorage{

    using Counters for Counters.Counter;
    uint256 original_price; // Price times 100 for int
    address public minter_address;
    Counters.Counter private tokenIDS;

    constructor() ERC721("Car","CAR"){
        minter_address = msg.sender;
    }

    function calculatePrice(uint256 current_car_mileage, uint256 driver_experience, uint256 mileage_cap, uint256 end_time) public returns (uint256){
        return 100;
    }

    modifier onlyMinter() {
        require(msg.sender == minter_address, "Only minter can call this");_;}

    function mintCAR(string memory tokenURI) public onlyMinter returns (uint256) {
        uint256 tokenID = tokenIDS.current();
        tokenIDS.increment();
        _mint(msg.sender, tokenID);
        _setTokenURI(tokenID, tokenURI);
        return tokenID;
    }

    function transferOwnership(uint256 tokenID, CarLeaseSystem.Lease memory l) public onlyMinter{
        require (l.state == CarLeaseSystem.State.Available, "This car is not available for transfer.");
        address payable owner = payable(ownerOf(tokenID));
        _transfer(owner, l.buyer, tokenID);
    }
}