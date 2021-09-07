// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MiraMe{
    
    
    // Events
    event NewContent(uint id, address creator);
    event ChangeSponsor(uint id, address creator, address sponsor);
    
    // constants
    uint sponsorPercentageOnSell = 70;
    uint creatorPercentageOnSell = 20;
    
    // structs
    struct Content{
        string hash;
        uint price;
    }
    
    address platform;
    Content[] public contents;
    
    mapping (uint => address) public contentToOwner;
    mapping (uint => address) public contentToSponsor;
    mapping (address => uint) public contentsByOwner;
    
    
    // Modifiers
    
    modifier onlyCreator(uint id, address _creator){
        require(contentToOwner[id] == _creator);
        _;
    }
    
    modifier onlySponsor(uint id, address _sponsor){
        require(contentToSponsor[id] == _sponsor);
        _;
    }
    
    modifier onlyCreatorOrSponsor(uint id, address _creatorOrSponsor){
        require(contentToOwner[id] == _creatorOrSponsor || contentToSponsor[id] == _creatorOrSponsor);
        _;
    }
    
    modifier onlyPlatform(){
        require(msg.sender == platform);
        _;
    }
    
    constructor(){
        platform = msg.sender;
    }
    
    // Private functions
    
    function _createContent(string memory _hash, uint price, address _creator) internal {
        contents.push(Content(_hash, price));
        uint id = contents.length;
        contentToOwner[id] = _creator;
        contentToSponsor[id] = _creator;
        contentsByOwner[_creator]++;
        emit NewContent(id, _creator);
    }
    
    function _changeSponsor(uint _id, address _newSponsor) internal {
        contentToSponsor[_id] = _newSponsor;
        address creator = contentToOwner[_id];
        emit ChangeSponsor(_id, creator, _newSponsor);
    }
    
    // Public functions
    
    function createContent(string calldata hash, uint price) public {
        require(price > 0.0001 ether);
        address owner = msg.sender;
        _createContent(hash, price, owner);
    }
    
    function changeSponsor(uint id, address newSponsor) public onlyCreatorOrSponsor(id, msg.sender){
        _changeSponsor(id, newSponsor);
    }
    
    function changePrice(uint id, uint price) public onlySponsor(id, msg.sender){
        contents[id].price = price;
    }
    
    function buyContent(uint _id) public payable {
        require(contents[_id].price <= msg.value);
        uint creatorFee = msg.value * creatorPercentageOnSell / 100;
        uint sponsorFee = msg.value * sponsorPercentageOnSell / 100;
        uint platformFee = msg.value - creatorFee - sponsorFee;
        
        payable(contentToOwner[_id]).transfer(creatorFee);
        payable(contentToSponsor[_id]).transfer(sponsorFee);
        payable(platform).transfer(platformFee);
    }
    
    function getContentsByCreator(address _creator) external view returns(uint[] memory) {
        uint[] memory result = new uint[](contentsByOwner[_creator]);
        uint counter = 0;
        for (uint i = 0; i < contents.length; i++) {
          if (contentToOwner[i] == _creator) {
            result[counter] = i;
            counter++;
          }
        }
        return result;
    }
    
    
    function changePercentages(uint sponsor, uint creator) public onlyPlatform {
        require(sponsor + creator <= 95);
        sponsorPercentageOnSell = sponsor;
        creatorPercentageOnSell = creator;
    }
    
    function getValuesStored() public view onlyPlatform returns(uint){
        return address(this).balance;
    } 
    
    function transferMoney() public onlyPlatform{
        payable(platform).transfer(address(this).balance);
    }
    
    receive() external payable {
        payable(platform).transfer(msg.value);
    }
    
    
    
}
