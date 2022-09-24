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
    uint256 private noAccessoriesAvailable = 0;

    /// @dev stores the cUsdToken Address
    address private cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    struct WristItem {
        address payable owner;
        string name;
        string image;
        string description;
        uint256 price;
        uint256 tempPrice;
        uint256 sold;
        uint256 units;
        uint256 nLikes;
    }

    mapping(uint256 => WristItem) private wristItems;

    mapping(uint256 => bool) private available;
    // keeps track of users that liked an item
    mapping(uint256 => mapping(address => bool)) private liked;

    modifier isOwner(uint256 _index) {
        require(
            wristItems[_index].owner == msg.sender,
            "Forbbiden: Owner Only"
        );
        _;
    }

    modifier validAmount(uint256 _price) {
        require(_price >= 1 ether, "Price must be at least one cusd");
        _;
    }

    modifier checkIfValidCustomer(uint256 _index) {
        require(
            wristItems[_index].owner != msg.sender,
            "Error: Only valid customers"
        );
        _;
    }

    modifier isAvailable(uint256 _index) {
        require(available[_index], "Item does not isAvailable");
        _;
    }

    /**
     * @dev allow users to add an item to the plaform
     * @notice Input data can't contain empty or incorrect values
     */
    function addItem(
        string calldata _name,
        string calldata _image,
        string calldata _description,
        uint256 _price,
        uint256 _units
    ) public validAmount(_price) {
        require(bytes(_name).length > 0, "Empty name");
        require(bytes(_image).length > 0, "Empty image url");
        require(bytes(_description).length > 0, "Empty description");
        uint256 index = noAccessoriesAvailable;
        noAccessoriesAvailable++;
        wristItems[index] = WristItem(
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
        available[index] = true;
    }

    /**
     * @dev allow items' owners to put a promo sale on their items
     */
    function promoSale(uint256 _index, uint256 _discount)
        external
        isAvailable(_index)
        isOwner(_index)
    {
        require(
            _discount >= 0 && _discount <= 100,
            "Discount percentage can only be between 0 and 100"
        );
        uint256 newPrice = wristItems[_index].price -
            ((_discount * wristItems[_index].price) / 100);
        wristItems[_index].price = newPrice;
    }

    /**
     * @dev allow items' owners to end a promo sale on their items
     * @notice the item's price will be set to the initial price of the item
     */
    function endPromoSale(uint256 _index)
        external
        isAvailable(_index)
        isOwner(_index)
    {
        wristItems[_index].price = wristItems[_index].tempPrice;
    }

    /**
     * @dev allow items' owners to remove their items from the platform
     * @dev mapping is reordered before cleanup of the item's data
     */
    function deleteItem(uint256 _index)
        public
        isOwner(_index)
        isAvailable(_index)
    {
        uint256 newLength = noAccessoriesAvailable - 1;
        wristItems[_index] = wristItems[newLength];
        delete (wristItems[newLength]);
        available[newLength] = false;
        noAccessoriesAvailable = newLength;
    }

    function viewItem(uint256 _index)
        public
        view
        isAvailable(_index)
        returns (WristItem memory)
    {
        return (wristItems[_index]);
    }

    /**
     * @dev allow users to buy an item
     * @param units number of items to buy
     */
    function buyItem(uint256 _index, uint256 units)
        external
        payable
        isAvailable(_index)
        checkIfValidCustomer(_index)
    {
        require(units > 0, "You must buy at least one unit");
        WristItem storage currentItem = wristItems[_index];
        require(currentItem.units >= units, "Not enough units in stock");
        uint256 amount = currentItem.price * units;
        currentItem.sold += units;
        uint256 unitsLeft = currentItem.units - units;
        currentItem.units = unitsLeft;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentItem.owner,
                amount
            ),
            "Transfer failed."
        );
    }

    /**
     * @dev allow users to buy all the units availalbe for an item
     */
    function buyAllUnitsItem(uint256 _index)
        external
        payable
        isAvailable(_index)
        checkIfValidCustomer(_index)
    {
        WristItem storage currentItem = wristItems[_index];
        require(currentItem.units > 0, "Item is out of stock");
        uint256 amount = currentItem.price * currentItem.units;
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                currentItem.owner,
                amount
            ),
            "Transfer failed."
        );
        uint256 newSoldAmount = currentItem.sold + currentItem.units;
        currentItem.sold = newSoldAmount;
        currentItem.units = 0;
    }

    /**
     * @dev allow users to tip the owner of an item
     */
    function tipMarketer(uint256 _index, uint256 _amount)
        external
        payable
        validAmount(_amount)
        isAvailable(_index)
        checkIfValidCustomer(_index)
    {
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                wristItems[_index].owner,
                _amount
            ),
            "Transfer failed."
        );
    }

    /**
     * @dev allow users to like an item
     * @notice users can like an item only once
     */
    function likeItem(uint256 _index)
        external
        isAvailable(_index)
        checkIfValidCustomer(_index)
    {
        require(!liked[_index][msg.sender], "You have already liked this item");
        liked[_index][msg.sender] = true;
        wristItems[_index].nLikes++;
    }

    function totalAccessoriesAvailable() public view returns (uint256) {
        return (noAccessoriesAvailable);
    }
}
