// SPDX-License-Identifier: MIT

/// @dev solitity version.
pragma solidity >=0.7.0 <0.9.0; //this contract works for solidty version from 0.7.0 to less than 0.9.0

/**
* @dev REquired interface of an ERC20 compliant contract.
*/
interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

/**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must isAvailable.
     *
     * Emits an {Approval} event.
     */
    function approve(address, uint256) external returns (bool);

 /**
     * @dev Transfers `tokenId` token from `from` to `to`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must isAvailable and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);


    function totalSupply() external view returns (uint256);

/*
*@dev Returns the number of tokens in``owner``'s acount.
*/
    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

/*
*@dev Emitted when `tokenId` token is transferred from `from` to `to`.
*/
    event Transfer(address indexed from, address indexed to, uint256 value);

/*
*@dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
*/  
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Accessories {
    


    uint private noAccessoriesAvailable = 0;

    /// @dev stores the cUsdToken Address
    address private cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct WristItem{
        address payable owner;
        string name;
        string image;
        string description;
        uint price;
        uint tempPrice;
        uint sold;
        uint units;
        uint nLikes;
    }

    mapping(uint => WristItem) private wristItems;

    mapping(uint => bool) private available;

    modifier isOwner(uint _index) {
        require(wristItems[_index].owner == msg.sender, "Forbbiden: Owner Only");
        _;
    }

    modifier validAmount(uint _price) {
        require(_price > 0, "Price must be at least one cusd");
        _;
    }

    modifier isAvailable(uint _index) {
        require(available[_index], "Item does not isAvailable");
        _;
    }

    function addItem(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        uint _price,
        uint _units
    ) public validAmount(_price) {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image url");
        require(bytes(_description).length > 0, "Empty description");
        wristItems[noAccessoriesAvailable] = WristItem(
            payable(msg.sender),
            _name,
            _image,
            _description,
            _price,
            _price,
            0,
            _units,
            0

        );
         available[noAccessoriesAvailable] = true;
        noAccessoriesAvailable++;
    }

    function promoSale(uint _index, uint _discount) external isAvailable(_index) isOwner(_index){
        uint newPrice = wristItems[_index].price - ((_discount * wristItems[_index].price )/100);
        wristItems[_index].price = newPrice;
    }

    function endPromoSale(uint _index) external isAvailable(_index) isOwner(_index){
        wristItems[_index].price = wristItems[_index].tempPrice;
    }
    

    function deleteItem(uint _index) isOwner(_index) isAvailable(_index) public{
        delete(wristItems[_index]);
        noAccessoriesAvailable--;
    }

    function viewItem(uint _index)
        public
        view
        isAvailable(_index)
        returns (WristItem memory)
    {
        return (wristItems[_index]);
    }

    function buyItem(uint _index,uint units) external payable isAvailable(_index) {
        require(
            wristItems[_index].owner != msg.sender,
            "You can't buy your own Items"
        );
        uint amount = wristItems[_index].price * units;
       
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                wristItems[_index].owner,
                amount
            ),
            "Transfer failed."
        );
        wristItems[_index].sold++;
        wristItems[_index].units = wristItems[_index].units - units;
    }

    function buyAllUnitsItem (uint _index) external payable isAvailable(_index){
        require(
            wristItems[_index].owner != msg.sender,
            "You can't buy your own Items"
        );
        uint amount = wristItems[_index].price * wristItems[_index].units;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                wristItems[_index].owner,
                amount
            ),
            "Transfer failed."
        );
         wristItems[_index].sold= wristItems[_index].units;
        wristItems[_index].units = 0;
       
    }
    
    function tipMarketer(uint _index, uint _amount) external payable
     validAmount(_amount) isAvailable(_index){
        require(
            wristItems[_index].owner != msg.sender,
            "You can't tip yourself"
        );
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                wristItems[_index].owner,
                _amount
            ),
            "Transfer failed."
        );
    }

    function likeItem( uint _index) external isAvailable(_index){
        require(
            wristItems[_index].owner != msg.sender,
            "You can't like your own item yourself"
        );
        wristItems[_index].nLikes++;
    }

    function totalAccessoriesAvailable() public view returns (uint) {
        return (noAccessoriesAvailable);
    }
}