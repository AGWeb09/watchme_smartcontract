// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract MiraMe{
    
    // Events
    /*
    * New Content by 'creator' has been added. It has id 'id'
    */
    event NewContent(uint id, address creator);
    /*
    * Content 'id', created by 'creator' change sponsor to 'sponsor'
    */ 
    event ChangeSponsor(uint id, address creator, address sponsor);
    
    // constants
    uint sponsorPercentageOnSell = 70;
    uint creatorPercentageOnSell = 20;
    uint minimumFee = 0.0001 ether;
    
    // structs
    struct Content{
        string hash;
        uint price;
    }
    
    address platform;
    Content[] public contents;
    
    mapping (uint => address) private contentToOwner;
    mapping (uint => address) private contentToSponsor;
    mapping (address => uint) private contentsByOwner;
    
    
    // Modifiers
    modifier onlyCreator(uint id){
        require(contentToOwner[id] == msg.sender, "Only Creator can do this");
        _;
    }

    modifier onlySponsor(uint id){
        require(contentToSponsor[id] == msg.sender, "Only Sponsor can do this");
        _;
    }

    modifier onlyCreatorOrSponsor(uint id){
        require(contentToOwner[id] == msg.sender || contentToSponsor[id] == msg.sender, "Only Creator or Sponsor can do this");
        _;
    }
    
    modifier onlyPlatform(){
        require(msg.sender == platform, "Only ME can do this.");
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
    
    /*
    * Creates a new Content with a given hash and a given price
    * Price has to be higher than minimumFee saved in the contract.
    * Price has to be in Wei.
    */ 
    function createContent(string calldata hash, uint price) public {
        require(price > minimumFee, "Price is too low");
        _createContent(hash, price, msg.sender);
    }
    
    /*
    * Changes the sponsor of the Content
    * Only the sponsor can change the sponsor. 
    * At the beginning, the creator IS the sponsor.
    * Check if the given ID exists
    */
    function changeSponsor(uint id, address newSponsor) public onlySponsor(id){
        require(contents.length >= id, "Content does not exists");
        _changeSponsor(id, newSponsor);
    }
    
    /*
    * Changes the price of the content.
    * Price has to be higher than minimuFee saved in the contract.
    * Price has to be in Wei.
    * Check if the given ID exists
    * Only the sponsor can change the sponsor.
    * At the beginning, the creator IS the sponsor.
    */
    function changePrice(uint id, uint price) public onlySponsor(id){
       require(price > minimumFee, "New Price is too low");
       require(contents[id].price >= 0, "Content does not exists");
       contents[id].price = price;
    }
    
    /*
    * Buy the Content, providing the value in wei.
    */
    function buyContent(uint _id) public payable {
        require(contents.length >= _id, "Content does not exists");
        require(contents[_id].price <= msg.value, "Your offer is below price");
        require(contentToSponsor[_id] != msg.sender, "This content is already yours!");
        uint creatorFee = msg.value * creatorPercentageOnSell / 100;
        uint sponsorFee = msg.value * sponsorPercentageOnSell / 100;
        uint platformFee = msg.value - creatorFee - sponsorFee;
        
        contentToSponsor[_id] = msg.sender;

        payable(contentToOwner[_id]).transfer(creatorFee);
        payable(contentToSponsor[_id]).transfer(sponsorFee);
        payable(platform).transfer(platformFee);
    }
    
    /*
    * Get the list of the contents by creator.
    */
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
    
    /*
    * Changes the percentage for all the contents.
    * The sponsor percentage and the creator percentage cannot overflow 95, for a minimum 5% percentage for the platform.
    */
    function changePercentages(uint _sponsor, uint _creator) public onlyPlatform {
        require(_sponsor + _creator <= 95, "Sponsor + Creator fees are too high");
        sponsorPercentageOnSell = _sponsor;
        creatorPercentageOnSell = _creator;
    }
    
    /*
    * Changes the minimum fee to operate.
    */
    function changeMinimumFee(uint _minimumFee) public onlyPlatform {
        minimumFee = _minimumFee;
    }

    /*
    * Get back all the money forom the contract.
    */
    function transferMoney() public onlyPlatform{
        payable(platform).transfer(address(this).balance);
    }
    
    
}
