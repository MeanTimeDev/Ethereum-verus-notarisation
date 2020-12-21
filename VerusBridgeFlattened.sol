// File: openzeppelin-solidity/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// File: contracts/VerusBridge/Token.sol

pragma solidity >=0.4.20;



contract Token is ERC20,ERC20Burnable {

    address private owner;

    constructor(string memory _name, string memory _symbol) ERC20(_name,_symbol) public {
        owner = msg.sender;
    }

    function mint(address to,uint256 amount) public {
        require(msg.sender == owner,"Only the contract owner can Mint");
        _mint(to, amount);

    }
}

// File: contracts/VerusBridge/TokenManager.sol

pragma solidity >=0.4.20;
pragma experimental ABIEncoderV2;


contract TokenManager {

    event TokenCreated(address tokenAddress);
    //array of contracts address mapped to the token name
    struct hostedToken{
        address contractAddress;
        bool VerusOwned;
        bool isRegistered;
    }
    mapping(string => hostedToken) vERC20Tokens;
    mapping(address => string) vERC20TokenNames;

    //receive tokens that arent owned by the contract these would need to be authorised before transfer
    function receiveERC20Tokens(address contractAddress,uint256 tokenAmount) public {
        //transfer the tokens to the contract address
        //if its not approved it wont work
        Token token = Token(contractAddress);
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= tokenAmount,"Not enough tokens have been approved");
        token.transferFrom(msg.sender,address(this),tokenAmount);   
        
        string memory tokenName = vERC20TokenNames[contractAddress];
        hostedToken memory tokenDetail = vERC20Tokens[tokenName];
        //if the token has been cerated by this contract then burn the token
        if(tokenDetail.VerusOwned){
            require(token.balanceOf(address(this)) >= tokenAmount,"Tokens didnt transfer");
            burnToken(contractAddress,tokenAmount);
        } else {
            //the contract stores the token
        }
    }

    function receiveERC20Tokens(string memory tokenName,uint256 tokenAmount) public {
        address contactAddress = getTokenAddress(tokenName);
        receiveERC20Tokens(contactAddress,tokenAmount);
    }
    
    function sendERC20Tokens(address contractAddress,uint256 tokenAmount,address destinationAddress) public returns(bool){
        string memory tokenName = vERC20TokenNames[contractAddress];
        hostedToken memory tokenDetail = vERC20Tokens[tokenName];
        
        //if the token has been created by this contract then burn the token
        
        if(tokenDetail.VerusOwned){
            mintToken(contractAddress,tokenAmount,destinationAddress);
        } else {
            //transfer from the 
            Token token = Token(contractAddress);
            token.transfer(destinationAddress,tokenAmount);   
        }
    }

    function sendERC20Tokens(string memory tokenName,uint256 tokenAmount,address destinationAddress) public {
        address contactAddress = getTokenAddress(tokenName);
        sendERC20Tokens(contactAddress,tokenAmount,destinationAddress);        
    }

    function deployNewToken(string memory tokenName, string memory symbol)
    public returns (address) {
        if(isToken(tokenName)) return getTokenAddress(tokenName);
        Token t = new Token(tokenName, symbol);
        vERC20Tokens[tokenName]= hostedToken(address(t),true,true);
        vERC20TokenNames[address(t)] = tokenName;
        emit TokenCreated(address(t));
        return address(t);
    }

    function balanceOf(address contractAddress,address account) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.balanceOf(account);
    }
    function approve(address contractAddress,address spender, uint256 amount) public {
        Token token = Token(contractAddress);
        token.approve(spender,amount);
    }
    function allowance(address contractAddress,address owner, address spender) public view returns(uint256){
        Token token = Token(contractAddress);
        return token.allowance(owner,spender);
    }

    function mintToken(address contractAddress,uint256 mintAmount,address recipient) public {
        Token token = Token(contractAddress);
        token.mint(recipient,mintAmount);
    }

    function burnToken(address contractAddress,uint burnAmount) public {
        Token token = Token(contractAddress);
        token.burn(burnAmount);
    }

    function addExistingToken(string memory name, address contactAddress) public{
        require(!isToken(name));
        vERC20Tokens[name] = hostedToken(contactAddress,false,true);
    }

    function isToken(string memory name) public view returns(bool){
        if(vERC20Tokens[name].isRegistered) return true;
        else return false;
    }

    function isVerusOwned(string memory name) public view returns(bool){
        if(vERC20Tokens[name].VerusOwned) return true;
        else return false;
    }

    function getTokenAddress(string memory name) public view returns(address){
        return vERC20Tokens[name].contractAddress;
    }

    function getTokenName(address tokenAddress) public view returns(string memory){
        return vERC20TokenNames[tokenAddress];
    }


}

// File: contracts/MMR/BLAKE2B/BLAKE2b_Constants.sol

pragma solidity >=0.5.16 <0.7.1;
contract BLAKE2_Constants{
    /*
    Constants, as defined in RFC 7693
    */


      uint64[8] public IV = [
          0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
          0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
          0x510e527fade682d1, 0x9b05688c2b3e6c1f,
          0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
      ];

      uint64 constant MASK_0 = 0xFF00000000000000;
      uint64 constant MASK_1 = 0x00FF000000000000;
      uint64 constant MASK_2 = 0x0000FF0000000000;
      uint64 constant MASK_3 = 0x000000FF00000000;
      uint64 constant MASK_4 = 0x00000000FF000000;
      uint64 constant MASK_5 = 0x0000000000FF0000;
      uint64 constant MASK_6 = 0x000000000000FF00;
      uint64 constant MASK_7 = 0x00000000000000FF;

      uint64 constant SHIFT_0 = 0x0100000000000000;
      uint64 constant SHIFT_1 = 0x0000010000000000;
      uint64 constant SHIFT_2 = 0x0000000001000000;
      uint64 constant SHIFT_3 = 0x0000000000000100;
}

// File: contracts/MMR/BLAKE2B/BLAKE2b.sol

// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.5.16 <0.7.1;


contract BLAKE2b is BLAKE2_Constants{

  struct BLAKE2b_ctx {
    uint256[4] b; //input buffer
    uint64[8] h;  //chained state
    uint128 t; //total bytes
    uint64 c; //Size of b
    uint outlen; //diigest output size
  }

event BlakeResult(uint64[8] blakeArray);

  // Mixing Function
  function G(uint64[16] memory v, uint a, uint b, uint c, uint d, uint64 x, uint64 y) public pure {

       // Dereference to decrease memory reads
       uint64 va = v[a];
       uint64 vb = v[b];
       uint64 vc = v[c];
       uint64 vd = v[d];

       //Optimised mixing function
       assembly{
         // v[a] := (v[a] + v[b] + x) mod 2**64
         va := addmod(add(va,vb),x, 0x10000000000000000)
         //v[d] := (v[d] ^ v[a]) >>> 32
         vd := xor(div(xor(vd,va), 0x100000000), mulmod(xor(vd, va),0x100000000, 0x10000000000000000))
         //v[c] := (v[c] + v[d])     mod 2**64
         vc := addmod(vc,vd, 0x10000000000000000)
         //v[b] := (v[b] ^ v[c]) >>> 24
         vb := xor(div(xor(vb,vc), 0x1000000), mulmod(xor(vb, vc),0x10000000000, 0x10000000000000000))
         // v[a] := (v[a] + v[b] + y) mod 2**64
         va := addmod(add(va,vb),y, 0x10000000000000000)
         //v[d] := (v[d] ^ v[a]) >>> 16
         vd := xor(div(xor(vd,va), 0x10000), mulmod(xor(vd, va),0x1000000000000, 0x10000000000000000))
         //v[c] := (v[c] + v[d])     mod 2**64
         vc := addmod(vc,vd, 0x10000000000000000)
         // v[b] := (v[b] ^ v[c]) >>> 63
         vb := xor(div(xor(vb,vc), 0x8000000000000000), mulmod(xor(vb, vc),0x2, 0x10000000000000000))
       }

       v[a] = va;
       v[b] = vb;
       v[c] = vc;
       v[d] = vd;
  }


  function compress(BLAKE2b_ctx memory ctx, bool last) internal view {
    //TODO: Look into storing these as uint256[4]
    uint64[16] memory v;
    uint64[16] memory m;


    for(uint i = 0; i<8; i++){
      v[i] = ctx.h[i]; // v[:8] = h[:8]
      v[i+8] = IV[i];  // v[8:] = IV
    }

    //
    v[12] = v[12] ^ uint64(ctx.t % 2**64);  //Lower word of t
    v[13] = v[13] ^ uint64(ctx.t / 2**64);

    if(last) v[14] = ~v[14];   //Finalization flag

    uint64 mi;  //Temporary stack variable to decrease memory ops
    uint b; // Input buffer

    for(uint i = 0; i < 16; i++){ //Operate 16 words at a time
      uint k = i%4; //Current buffer word
      mi = 0;
      if(k == 0){
        b = ctx.b[i/4];  //Load relevant input into buffer
      }

      //Extract relevent input from buffer
      assembly{
        mi := and(div(b,exp(2,mul(64,sub(3,k)))), 0xFFFFFFFFFFFFFFFF)
      }

      //Flip endianness
      m[i] = getWords(mi);
    }

    //Mix m

          G(v, 0, 4, 8, 12, m[0], m[1]);
          G(v, 1, 5, 9, 13, m[2], m[3]);
          G(v, 2, 6, 10, 14, m[4], m[5]);
          G(v, 3, 7, 11, 15, m[6], m[7]);
          G(v, 0, 5, 10, 15, m[8], m[9]);
          G(v, 1, 6, 11, 12, m[10], m[11]);
          G(v, 2, 7, 8, 13, m[12], m[13]);
          G(v, 3, 4, 9, 14, m[14], m[15]);


          G(v, 0, 4, 8, 12, m[14], m[10]);
          G(v, 1, 5, 9, 13, m[4], m[8]);
          G(v, 2, 6, 10, 14, m[9], m[15]);
          G(v, 3, 7, 11, 15, m[13], m[6]);
          G(v, 0, 5, 10, 15, m[1], m[12]);
          G(v, 1, 6, 11, 12, m[0], m[2]);
          G(v, 2, 7, 8, 13, m[11], m[7]);
          G(v, 3, 4, 9, 14, m[5], m[3]);


          G(v, 0, 4, 8, 12, m[11], m[8]);
          G(v, 1, 5, 9, 13, m[12], m[0]);
          G(v, 2, 6, 10, 14, m[5], m[2]);
          G(v, 3, 7, 11, 15, m[15], m[13]);
          G(v, 0, 5, 10, 15, m[10], m[14]);
          G(v, 1, 6, 11, 12, m[3], m[6]);
          G(v, 2, 7, 8, 13, m[7], m[1]);
          G(v, 3, 4, 9, 14, m[9], m[4]);


          G(v, 0, 4, 8, 12, m[7], m[9]);
          G(v, 1, 5, 9, 13, m[3], m[1]);
          G(v, 2, 6, 10, 14, m[13], m[12]);
          G(v, 3, 7, 11, 15, m[11], m[14]);
          G(v, 0, 5, 10, 15, m[2], m[6]);
          G(v, 1, 6, 11, 12, m[5], m[10]);
          G(v, 2, 7, 8, 13, m[4], m[0]);
          G(v, 3, 4, 9, 14, m[15], m[8]);


          G(v, 0, 4, 8, 12, m[9], m[0]);
          G(v, 1, 5, 9, 13, m[5], m[7]);
          G(v, 2, 6, 10, 14, m[2], m[4]);
          G(v, 3, 7, 11, 15, m[10], m[15]);
          G(v, 0, 5, 10, 15, m[14], m[1]);
          G(v, 1, 6, 11, 12, m[11], m[12]);
          G(v, 2, 7, 8, 13, m[6], m[8]);
          G(v, 3, 4, 9, 14, m[3], m[13]);


          G(v, 0, 4, 8, 12, m[2], m[12]);
          G(v, 1, 5, 9, 13, m[6], m[10]);
          G(v, 2, 6, 10, 14, m[0], m[11]);
          G(v, 3, 7, 11, 15, m[8], m[3]);
          G(v, 0, 5, 10, 15, m[4], m[13]);
          G(v, 1, 6, 11, 12, m[7], m[5]);
          G(v, 2, 7, 8, 13, m[15], m[14]);
          G(v, 3, 4, 9, 14, m[1], m[9]);


          G(v, 0, 4, 8, 12, m[12], m[5]);
          G(v, 1, 5, 9, 13, m[1], m[15]);
          G(v, 2, 6, 10, 14, m[14], m[13]);
          G(v, 3, 7, 11, 15, m[4], m[10]);
          G(v, 0, 5, 10, 15, m[0], m[7]);
          G(v, 1, 6, 11, 12, m[6], m[3]);
          G(v, 2, 7, 8, 13, m[9], m[2]);
          G(v, 3, 4, 9, 14, m[8], m[11]);


          G(v, 0, 4, 8, 12, m[13], m[11]);
          G(v, 1, 5, 9, 13, m[7], m[14]);
          G(v, 2, 6, 10, 14, m[12], m[1]);
          G(v, 3, 7, 11, 15, m[3], m[9]);
          G(v, 0, 5, 10, 15, m[5], m[0]);
          G(v, 1, 6, 11, 12, m[15], m[4]);
          G(v, 2, 7, 8, 13, m[8], m[6]);
          G(v, 3, 4, 9, 14, m[2], m[10]);


          G(v, 0, 4, 8, 12, m[6], m[15]);
          G(v, 1, 5, 9, 13, m[14], m[9]);
          G(v, 2, 6, 10, 14, m[11], m[3]);
          G(v, 3, 7, 11, 15, m[0], m[8]);
          G(v, 0, 5, 10, 15, m[12], m[2]);
          G(v, 1, 6, 11, 12, m[13], m[7]);
          G(v, 2, 7, 8, 13, m[1], m[4]);
          G(v, 3, 4, 9, 14, m[10], m[5]);


          G(v, 0, 4, 8, 12, m[10], m[2]);
          G(v, 1, 5, 9, 13, m[8], m[4]);
          G(v, 2, 6, 10, 14, m[7], m[6]);
          G(v, 3, 7, 11, 15, m[1], m[5]);
          G(v, 0, 5, 10, 15, m[15], m[11]);
          G(v, 1, 6, 11, 12, m[9], m[14]);
          G(v, 2, 7, 8, 13, m[3], m[12]);
          G(v, 3, 4, 9, 14, m[13], m[0]);


          G(v, 0, 4, 8, 12, m[0], m[1]);
          G(v, 1, 5, 9, 13, m[2], m[3]);
          G(v, 2, 6, 10, 14, m[4], m[5]);
          G(v, 3, 7, 11, 15, m[6], m[7]);
          G(v, 0, 5, 10, 15, m[8], m[9]);
          G(v, 1, 6, 11, 12, m[10], m[11]);
          G(v, 2, 7, 8, 13, m[12], m[13]);
          G(v, 3, 4, 9, 14, m[14], m[15]);


          G(v, 0, 4, 8, 12, m[14], m[10]);
          G(v, 1, 5, 9, 13, m[4], m[8]);
          G(v, 2, 6, 10, 14, m[9], m[15]);
          G(v, 3, 7, 11, 15, m[13], m[6]);
          G(v, 0, 5, 10, 15, m[1], m[12]);
          G(v, 1, 6, 11, 12, m[0], m[2]);
          G(v, 2, 7, 8, 13, m[11], m[7]);
          G(v, 3, 4, 9, 14, m[5], m[3]);



    //XOR current state with both halves of v
    for(uint i = 0; i<8; ++i){
      ctx.h[i] = ctx.h[i] ^ v[i] ^ v[i+8];
    }

  }


  function init(BLAKE2b_ctx memory ctx, uint64 outlen, bytes memory key, uint64[2] memory salt, uint64[2] memory person) internal{

      if(outlen == 0 || outlen > 64 || key.length > 64) revert("Outlen must be greater than 0 and less than 64");

      //Initialize chained-state to IV
      for(uint i = 0; i < 8; i++){
        ctx.h[i] = IV[i];
      }

      // Set up parameter block
      ctx.h[0] = ctx.h[0] ^ 0x01010000 ^ shift_left(uint64(key.length), 8) ^ outlen;
      ctx.h[4] = ctx.h[4] ^ salt[0];
      ctx.h[5] = ctx.h[5] ^ salt[1];
      ctx.h[6] = ctx.h[6] ^ person[0];
      ctx.h[7] = ctx.h[7] ^ person[1];

      ctx.outlen = outlen;

      //Run hash once with key as input
      if(key.length > 0){
        update(ctx, key);
        ctx.c = 128;
      }
  }


  function update(BLAKE2b_ctx memory ctx, bytes memory input) internal {

    for(uint i = 0; i < input.length; i++){
      //If buffer is full, update byte counters and compress
      if(ctx.c == 128){
        ctx.t += ctx.c;
        compress(ctx, false);
        ctx.c = 0;
      }

      //Update temporary counter c
      uint c = ctx.c++;

      // b -> ctx.b
      uint[4] memory b = ctx.b;
      uint8 a = uint8(input[i]);

      // ctx.b[c] = a
      assembly{
        mstore8(add(b,c),a)
      }
    }
  }


  function finalize(BLAKE2b_ctx memory ctx, uint64[8] memory out) internal {
    // Add any uncounted bytes
    ctx.t += ctx.c;

    // Compress with finalization flag
    compress(ctx,true);

    //Flip little to big endian and store in output buffer
    for(uint i = 0; i < ctx.outlen / 8; i++){
      out[i] = getWords(ctx.h[i]);
    }

    //Properly pad output if it doesn't fill a full word
    if(ctx.outlen < 64){
      out[ctx.outlen/8] = shift_right(getWords(ctx.h[ctx.outlen/8]),64-8*(ctx.outlen%8));
    }

  }

  //Helper function for full hash function
  function blake2b(bytes memory input,
    bytes memory key,
    bytes memory salt,
    bytes memory personalization,
    uint64 outlen) public returns(uint64[8] memory){

    BLAKE2b_ctx memory ctx;
    uint64[8] memory out;
    //out = [uint64(0),uint64(0),uint64(0),uint64(0),uint64(0),uint64(0),uint64(0),uint64(0)];
    init(ctx, outlen, key, formatInput(salt), formatInput(personalization));
    //break the input array into 128 byte chunks
    update(ctx, input);
    finalize(ctx, out);
    emit BlakeResult(out);
    return out;
  }

  function blake2b(bytes memory input, bytes memory key, uint64 outlen) public returns (uint64[8] memory){
    
    return blake2b(input, key, "", "", outlen);
    //return([uint64(23),uint64(23),uint64(23),uint64(23),uint64(23),uint64(23),uint64(23),uint64(23)]);
  }

// Utility functions

  //Flips endianness of words
  function getWords(uint64 a) public pure returns (uint64 b) {
    return  (a & MASK_0) / SHIFT_0 ^
            (a & MASK_1) / SHIFT_1 ^
            (a & MASK_2) / SHIFT_2 ^
            (a & MASK_3) / SHIFT_3 ^
            (a & MASK_4) * SHIFT_3 ^
            (a & MASK_5) * SHIFT_2 ^
            (a & MASK_6) * SHIFT_1 ^
            (a & MASK_7) * SHIFT_0;
  }

  function shift_right(uint64 a, uint shift) public pure returns(uint64 b){
    return uint64(a / 2**shift);
  }

  function shift_left(uint64 a, uint shift) public pure returns(uint64){
    return uint64((a * 2**shift) % (2**64));
  }

  //bytes -> uint64[2]
  function formatInput(bytes memory input) public pure returns (uint64[2] memory output){
    for(uint i = 0; i<input.length; i++){
        output[i/8] = output[i/8] ^ shift_left(uint64(uint8(input[i])), 64-8*(i%8+1));
    }
        output[0] = getWords(output[0]);
        output[1] = getWords(output[1]);
  }

  function formatOutput(uint64[8] memory input) public pure returns(bytes32[2] memory){
    bytes32[2] memory result;

    for(uint i = 0; i < 8; i++){
        result[i/4] = result[i/4] ^ bytes32(input[i] * 2**(64*(3-i%4)));
    }
    return result;
  }
}

// File: contracts/MMR/MMRProof.sol

// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;

pragma experimental ABIEncoderV2;

contract MMRProof{

    uint256 mmrRoot;
    BLAKE2b blake2b;
    bytes verusKey = "VerusDefaultHash";
    event JoinEvent(bytes joinedValue,uint8 eventType);
    event HashEvent(bytes32 newHash,uint8 eventType);

    constructor() public{
        blake2b = new BLAKE2b();
    }

    function predictedRootHash(bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bytes32){
        
        require(_hashIndex >= 0,"Index cannot be less than 0");
        require(_branch.length > 0,"Branch must be longer than 0");
        uint branchLength = _branch.length;
        bytes32 hashInProgress;
        uint64[8] memory blakeResult;
        bytes memory joined;
        verusKey = "";
        hashInProgress = bytesToBytes32(abi.encodePacked(_hashToCheck));

       for(uint i = 0;i < branchLength; i++){
            if(_hashIndex & 1 > 0){
                require(_branch[i] != _hashToCheck,"Value can be equal to node but never on the right");
                //join the two arrays and pass to blake2b
                joined = abi.encodePacked(_branch[i],hashInProgress);
                emit JoinEvent(joined,1);
            } else {
                joined = abi.encodePacked(hashInProgress,_branch[i]);
                emit JoinEvent(joined,2);
            }
            blakeResult = blake2b.blake2b(joined,verusKey,32);
            hashInProgress = bytesToBytes32(abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]));
            emit HashEvent(hashInProgress,3);
            _hashIndex >>= 1;
        }

        return hashInProgress;

    }

    function checkHashInRoot(bytes32 _mmrRoot,bytes32 _hashToCheck,uint _hashIndex,bytes32[] memory _branch) public returns(bool){
        bytes32 calculatedHash = predictedRootHash(_hashToCheck,_hashIndex,_branch);
        if(_mmrRoot == calculatedHash) return true;
        else return false;
    }

    function bytesToBytes32(bytes memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function createHash(bytes memory toHash,bytes memory personalisation,bool flipped) public returns(bytes32){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(toHash);
        bytes memory key;
        bytes memory salt;

        blakeResult = blake2b.blake2b(testInput,key,salt,personalisation,32);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);

        //we flip the bytes array to match up with Verus Hash    
        bytes32 bytes32hash = bytesToBytes32(hashInProgress);   
        if(flipped == true) bytes32hash = reverseBytes(bytes32hash);
        return bytes32hash;
    }

    function createHash(bytes memory toHash,bytes memory personalisation) public returns(bytes32){
        return createHash(toHash,personalisation,false);
    }

    function reverseBytes(bytes32 _bytes32) public pure returns (bytes32) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[(31-i)];
        }
        return bytesToBytes32(bytesArray);
    }


 

    function create64Hash(bytes memory testString,bytes memory key) public returns(bytes memory){
        uint64[8] memory blakeResult;
        bytes memory testInput = abi.encodePacked(testString);
        
        blakeResult = blake2b.blake2b(testInput,key,64);
        bytes memory hashInProgress = abi.encodePacked(blakeResult[0],blakeResult[1],blakeResult[2],blakeResult[3],
                blakeResult[4],blakeResult[5],blakeResult[6],blakeResult[7]);
        return hashInProgress;
    }
}

// File: contracts/VerusNotarizer/VerusNotarizer.sol

// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;


contract VerusNotarizer{

    //last notarized blockheight
    uint32 public lastBlockHeight;
    //CurrencyState private lastCurrencyState;
    //allows for the contract to be upgradable
    bool public deprecated;
    address public upgradedAddress;
    //number of notaries required
    uint8 requiredNotaries = 13;

    //list of all notarizers mapped to allow for quick searching
    mapping (address => bool) private komodoNotaries;
    //mapped blockdetails
    mapping (uint32 => bytes) public notarizedDataEntries;
    uint32[] public blockHeights;
    //used to record the number of notaries
    uint8 private notaryCount;

    struct NotarizedData{
        uint32 version;
        uint32 protocol;
        uint160 currencyID;
        uint160 notaryDest;
        uint32 notarizationHeight;
        uint256 mmrRoot;
        uint256 notarizationPreHash;
        uint256 compactPower;
    }

    struct TestData{
        uint32 version;
        uint32 protocol;
        uint160 currencyID;
        uint160 notaryDest;
        uint32 notarizationHeight;
        uint256 mmrRoot;
    }
  /*  
    struct CurrencyState{
        uint64[] reserveIn;
        uint64[] nativeIn;
        uint64[] reserveOut;
        uint64[] conversionPrice;
        uint64[] fees;
        uint64[] conversionFees;
    }
  */  
    // Notifies when the contract is deprecated
    event Deprecate(address newAddress);
    // Notifies when a new block hash is published
    event NewBlock(NotarizedData notarizedData,uint64 notarizedDataHeight);
    event signedAddress(address signedAddress);

    constructor() public {
        deprecated = false;
        notaryCount = 0;
        lastBlockHeight = 0;
        //add in the owner as the first notary
        address msgSender = msg.sender;
        komodoNotaries[msgSender] = true;
        notaryCount++;
    }

    modifier onlyNotary() {
        address msgSender = msg.sender;
        require(komodoNotaries[msgSender] == true, "Caller is not a notary");
        _;
    }

    function addNotary(address _notary,
        bytes32 _notarizedAddressHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public onlyNotary
    returns(bool){
        require(isNotarized(_notarizedAddressHash,_rs,_ss,_vs),"Function can only be executed by notaries");
        require(!deprecated,"Contract has been deprecated");
        //if the the komodoNotaries is full reject
        require(notaryCount < 60,"Cant have more than 60 notaries");
        //if the notary already is in the komodNotaries then reject
        require(!komodoNotaries[_notary],"Notary already exists");

        komodoNotaries[_notary] = true;
        notaryCount++;
        return true;

    }

    function removeNotary(address _notary) public onlyNotary
    returns(bool){

        require(!deprecated,"Contract has been deprecated");
        //if the notary is not in the list then fail
        require(komodoNotaries[_notary] == true,"Notary does not exist");
        //there must be at least one notary in the contract perhaps?
        require(notaryCount > 1,"Must have more than one notary");
        //need to look at this no easy way to delete from a mapping
        delete komodoNotaries[_notary];
        notaryCount--;
        return true;

    }

    //this function allows for intially expanding out the number of notaries
    function currentNotariesRequired() public view returns(uint8){
        if(notaryCount == 1) return 1;
        uint halfNotaryCount = notaryCount/2;
        if(halfNotaryCount > requiredNotaries) return requiredNotaries;
        else return uint8(halfNotaryCount);
    }

    function isNotarized(bytes32 notarizedDataHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) private view returns(bool){
        
        address signingAddress;
        //total number of signatures that have been validated
        uint8 numberOfSignatures = 0;

        //loop through the arrays, check the following:
        //does the hash in the hashedBlocks match the komodoBlockHash passed in
        for(uint i = 0; i < _rs.length; i++){
            //if the address is in the notary array increment the number of signatures
            signingAddress = recoverSigner(notarizedDataHash, _vs[i], _rs[i], _ss[i]);
            if(komodoNotaries[signingAddress]) {
                numberOfSignatures++;
            }
        }
        uint8 _requiredNotaries = currentNotariesRequired();
        if(numberOfSignatures >= _requiredNotaries){
            return true;
        } else return false;

    }

    function setLatestData(NotarizedData memory _notarizedDataDetail,
        bytes32 _notarizedDataHash,
        bytes32[] memory _rs,
        bytes32[] memory _ss,
        uint8[] memory _vs) public onlyNotary returns(bool){

        require(!deprecated,"Contract has been deprecated");
        require(komodoNotaries[msg.sender],"Only a notary can call this function");
        require((_rs.length == _ss.length) && (_rs.length == _vs.length),"Signature arrays must be of equal length");
        require(_notarizedDataDetail.notarizationHeight > lastBlockHeight,"Block Height must be greater than current block height");

        bytes memory serializedBlock = serializeData(_notarizedDataDetail);
        //check the hash of the data
        //need to check the block hash matches the hashed notarized block
        
        //if there is greater than 13 proper signatories then set the block hash
        if(isNotarized(_notarizedDataHash,_rs,_ss,_vs)){
            notarizedDataEntries[_notarizedDataDetail.notarizationHeight] = serializedBlock;
            blockHeights.push(_notarizedDataDetail.notarizationHeight);
            lastBlockHeight = _notarizedDataDetail.notarizationHeight;
            //lastCurrencyState = _currencyState;
            emit NewBlock(_notarizedDataDetail,lastBlockHeight);
            return true;
        } else return false;
    }

    function recoverSigner(bytes32 h, uint8 v, bytes32 r, bytes32 s) private pure returns (address) {
        address addr = ecrecover(h, v, r, s);
        return addr;
    }


    function getLastNotarizedData() public view returns(NotarizedData memory){

        require(!deprecated,"Contract has been deprecated");
        return deSerializeData(notarizedDataEntries[lastBlockHeight]);

    }
    /*
    function getLastCurrencyState() public view returns(CurrencyState memory){
        require(!deprecated,"Contract has been deprecated");
        return lastCurrencyState;
    }*/

    function getNotarizedData(uint32 _blockHeight) public view returns(NotarizedData memory){

        return deSerializeData(notarizedDataEntries[_blockHeight]);

    }

    function getLastBlockHeight() public view returns(uint32){

        require(!deprecated,"Contract has been deprecated");
        return lastBlockHeight;
    }

    function getAllBlockHeights() public view returns(uint32[] memory){
        return blockHeights;
    }

    function deSerializeData(bytes memory _serializedBlock) private pure returns(NotarizedData memory){
        NotarizedData memory deserializedBlock;

        (deserializedBlock.version,
        deserializedBlock.protocol,
        deserializedBlock.currencyID,
        deserializedBlock.notaryDest,
        deserializedBlock.notarizationHeight,
        deserializedBlock.mmrRoot,
        deserializedBlock.notarizationPreHash,
        deserializedBlock.compactPower
        ) = abi.decode(_serializedBlock,(uint32,uint32,uint160,uint160,uint32,uint256,uint256,uint256));

        return deserializedBlock;
    }

    function serializeData(NotarizedData memory _deserializedBlock) private pure returns(bytes memory){

        return abi.encode(_deserializedBlock.version,
        _deserializedBlock.protocol,
        _deserializedBlock.currencyID,
        _deserializedBlock.notaryDest,
        _deserializedBlock.notarizationHeight,
        _deserializedBlock.mmrRoot,
        _deserializedBlock.notarizationPreHash,
        _deserializedBlock.compactPower);

    }

    /*** temporary code for use on test net only will be removed for production */

    function kill() public onlyNotary{
        selfdestruct(msg.sender);
    }

    /**
    * deprecate current contract
    */
    function deprecate(address _upgradedAddress) public onlyNotary {
        require(!deprecated,"Contract has been deprecated");
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);

    }

}

// File: contracts/Standard/Memory.sol

pragma solidity >=0.4.21 <0.7.0;
//pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";


library Memory {

    // Size of a word, in bytes.
    uint internal constant WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint internal constant BYTES_HEADER_SIZE = 32;
    // Address of the free memory pointer.
    uint internal constant FREE_MEM_PTR = 0x40;

    // Compares the 'len' bytes starting at address 'addr' in memory with the 'len'
    // bytes starting at 'addr2'.
    // Returns 'true' if the bytes are the same, otherwise 'false'.
    function equals(uint addr, uint addr2, uint len) internal pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    // Compares the 'len' bytes starting at address 'addr' in memory with the bytes stored in
    // 'bts'. It is allowed to set 'len' to a lower value then 'bts.length', in which case only
    // the first 'len' bytes will be compared.
    // Requires that 'bts.length >= len'
    function equals(uint addr, uint len, bytes memory bts) internal pure returns (bool equal) {
        require(bts.length >= len);
        uint addr2;
        assembly {
            addr2 := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        return equals(addr, addr2, len);
    }

    // Allocates 'numBytes' bytes in memory. This will prevent the Solidity compiler
    // from using this area of memory. It will also initialize the area by setting
    // each byte to '0'.
    function allocate(uint numBytes) internal pure returns (uint addr) {
        // Take the current value of the free memory pointer, and update.
        assembly {
            addr := mload(/*FREE_MEM_PTR*/0x40)
            mstore(/*FREE_MEM_PTR*/0x40, add(addr, numBytes))
        }
        uint words = (numBytes + WORD_SIZE - 1) / WORD_SIZE;
        for (uint i = 0; i < words; i++) {
            assembly {
                mstore(add(addr, mul(i, /*WORD_SIZE*/32)), 0)
            }
        }
    }

    // Copy 'len' bytes from memory address 'src', to address 'dest'.
    // This function does not check the or destination, it only copies
    // the bytes.
    function copy(uint src, uint dest, uint len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        // Copy remaining bytes
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    // Returns a memory pointer to the provided bytes array.
    function ptr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := bts
        }
    }

    // Returns a memory pointer to the data portion of the provided bytes array.
    function dataPtr(bytes memory bts) internal pure returns (uint addr) {
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    // Creates a 'bytes memory' variable from the memory address 'addr', with the
    // length 'len'. The function will allocate new memory for the bytes array, and
    // the 'len bytes starting at 'addr' will be copied into that new memory.
    function toBytes(uint addr, uint len) internal pure returns (bytes memory bts) {
        bts = new bytes(len);
        uint btsptr;
        assembly {
            btsptr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
        copy(addr, btsptr, len);
    }

    // Get the word stored at memory address 'addr' as a 'uint'.
    function toUint(uint addr) internal pure returns (uint n) {
        assembly {
            n := mload(addr)
        }
    }

    // Get the word stored at memory address 'addr' as a 'bytes32'.
    function toBytes32(uint addr) internal pure returns (bytes32 bts) {
        assembly {
            bts := mload(addr)
        }
    }

    /*
    // Get the byte stored at memory address 'addr' as a 'byte'.
    function toByte(uint addr, uint8 index) internal pure returns (byte b) {
        require(index < WORD_SIZE);
        uint8 n;
        assembly {
            n := byte(index, mload(addr))
        }
        b = byte(n);
    }
    */
}

// File: contracts/VerusBridge/VerusBridge.sol

// SPDX-License-Identifier: MIT
// Bridge between ethereum and verus

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;







contract VerusBridge {
 
    //list of erc20 tokens that can be accessed,
    //the contract must be able to mint and burn coins on the contract
    //defines the tokenManager which creates the erc20
    TokenManager tokenManager;
    VerusNotarizer verusNotarizer;
    MMRProof mmrProof;

    uint256 feesHeld = 0;
    uint256 ethHeld = 0;

    bytes verusKey = "VerusDefaultHash";
    uint64 transactionsPerCall = 10;
    string VRSCEthTokenName = ".eth.";
    uint256 transactionFee = 100000000000000; //0.0001 eth


    //pending transactions array
    struct BridgeTransaction {
        address targetAddress;
        string tokenName;
        uint256 tokenAmount;
    }

    struct CompletedTransaction{
        uint256 blockNumber;
        BridgeTransaction[] includedTransactions;
        bool completed;
    }

    BridgeTransaction[] private pendingOutboundTransactions;
    BridgeTransaction[][] private readyOutboundTransactions;
    //to allow for a singe proof for a block of transactions we generate a hash of the transactions in a block
    //that can then be retrieved and used as a single proof of the transactions
    bytes32[] private readyOutboundTransactionsHashes;

    mapping (bytes32 => CompletedTransaction) private completedInboundTransactions;
    event ReceivedFromVerus(BridgeTransaction transaction);

    constructor(address notarizerAddress,address mmrAddress,address tokenManagerAddress) public {
        mmrProof =  MMRProof(mmrAddress);
        verusNotarizer = VerusNotarizer(notarizerAddress);
        tokenManager = TokenManager(tokenManagerAddress);
        //initialise the hash array
        readyOutboundTransactionsHashes.push(0x00);
        
    }

    function getTransactionsPerCall() public view returns(uint64){
        return transactionsPerCall;
    }

    function sendEth(uint256 _ethAmount,address payable _targetAddress) private {
        //do we take fees here????
        require(_ethAmount >= address(this).balance,"Requested amount exceeds contract balance");
        _targetAddress.transfer(_ethAmount);
    }

    function receiveFromVerusChain(BridgeTransaction[] memory _newTransactions, uint32 _hashIndex, bytes32[] memory _transactionsProof, uint32 _blockHeight) public returns(bytes32){   
        //check the transaction has not already been processed
        bytes32 newTransactionHash = createTransactionsHash(_newTransactions);
        require(!completedInboundTransactions[newTransactionHash].completed ,"Transactions have been already processed");
        //check the transaction is in the mmr contains the relevant hash
        //require(confirmTransactionInMMR(_newTransactions,_hashIndex,_transactionsProof,_blockHeight) == true,"Transactions are not in the MMR root hash");
        
        //loop through the transactions and execute
        for(uint i = 0; i < _newTransactions.length; i++){
            if(keccak256(abi.encodePacked(_newTransactions[i].tokenName)) == keccak256(abi.encodePacked(VRSCEthTokenName))) {
                sendEth(_newTransactions[i].tokenAmount,payable(_newTransactions[i].targetAddress));
                ethHeld -= _newTransactions[i].tokenAmount;
            } else {
                tokenManager.sendERC20Tokens(_newTransactions[i].tokenName,_newTransactions[i].tokenAmount,_newTransactions[i].targetAddress);
            }
            
            //create an array in storage of transactions as memory cant be added to a storage array
            completedInboundTransactions[newTransactionHash].blockNumber = block.number;
            completedInboundTransactions[newTransactionHash].includedTransactions.push(_newTransactions[i]);
            emit ReceivedFromVerus(_newTransactions[i]);
        }

        return newTransactionHash;
        
    }

    function sendEthToVerus(address _targetAddress) public payable returns(uint256){
        //calculate amount of eth to send
        require(msg.value > transactionFee,"Ethereum must be sent with the transaction to be sent to the Verus Chain");
        uint256 amount = msg.value - transactionFee;
        ethHeld += amount;
        feesHeld += transactionFee;
        _sendToVerus(VRSCEthTokenName,amount,_targetAddress);
        return amount;
    }

    function sendERC20ToVerus(string memory _tokenName, uint256 _tokenAmount, address _targetAddress) public payable {
        require(msg.value >= transactionFee,"Please send the appropriate transacion fee.");
        require(keccak256(abi.encodePacked(_tokenName)) != keccak256(abi.encodePacked(VRSCEthTokenName)),"To send eth use sendEthToVerus");
        feesHeld += msg.value;
        //claim fees
        _sendToVerus(_tokenName,_tokenAmount,_targetAddress);
    }

    function _sendToVerus(string memory _tokenName, uint256 _tokenAmount, address _targetAddress) private {
        //if the tokens have been approved for VerusBridge, approve the tokenManager contract to transfer them over
        address tokenAddress = tokenManager.getTokenAddress(_tokenName);
        Token token = Token(tokenAddress);
        uint256 allowedTokens = token.allowance(msg.sender,address(this));
        require( allowedTokens >= _tokenAmount,"This contract must have an allowance of greater than or equal to the number of tokens");
        //transfer the tokens to this contract
        token.transferFrom(msg.sender,address(this),_tokenAmount); 
        token.approve(address(tokenManager),_tokenAmount);  
        //give an approval for the tokenmanagerinstance to spend the tokens
        tokenManager.receiveERC20Tokens(_tokenName,_tokenAmount);
        pendingOutboundTransactions.push(BridgeTransaction(_targetAddress,_tokenName,_tokenAmount));
        //create a hash of the transaction values and add that to the last value 
        //of the readyOutboundTransactionsHashes;
        readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1] = keccak256(abi.encodePacked(readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1],_tokenName,_tokenAmount,_targetAddress));

        if(pendingOutboundTransactions.length >= transactionsPerCall){
            //move the array to readyOutboundTransactions
            readyOutboundTransactions.push(pendingOutboundTransactions);
            readyOutboundTransactionsHashes.push(0x00);
            delete pendingOutboundTransactions;
        }
    }

    function testKeccak(string memory _tokenName, uint256 _tokenAmount, address _targetAddress) public view returns(bytes memory){
        //return keccak256(abi.encodePacked(readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1],_tokenName,_tokenAmount,_targetAddress));
        return abi.encodePacked(readyOutboundTransactionsHashes[readyOutboundTransactionsHashes.length - 1],_tokenName,_tokenAmount,_targetAddress);
    
    }
    /**
    returns a list of transactions to be processed on the verus chain
    */
    
    function outboundTransactionsIndex() public view returns(uint){
        return readyOutboundTransactions.length;
    }

    function getTransactionsHash(uint _tIndex) public view returns(bytes32){
        return readyOutboundTransactionsHashes[_tIndex];
    }

    function getTransactionsToProcess(uint _tIndex) public view returns(BridgeTransaction[] memory){
        return readyOutboundTransactions[_tIndex];
    }

    function getPendingOutboundTransactions() public view returns(BridgeTransaction[] memory){
        return pendingOutboundTransactions;
    }

    function getCompletedInboundTransaction(bytes32 transactionHash) public view returns(CompletedTransaction memory){
        return completedInboundTransactions[transactionHash];
    }

    /**
    deploy a new token
     */
    function createToken(string memory verusAddress,string memory ticker) public returns(address){
        return tokenManager.deployNewToken(verusAddress,ticker);
    }


    function confirmTransactionInMMR(BridgeTransaction[] memory _newTransactions, 
        uint32 _hashIndex,
        bytes32[] memory _transactionsProof,
        uint32 _blockHeight) private returns(bool){
        
        //loop through the transactions and create a hash of the list
        bytes32 hashedTransactions = createTransactionsHash(_newTransactions);
        //get the mmrRoot relating to the blockheight from the notarized data
        VerusNotarizer.NotarizedData memory verusNotarizedData = verusNotarizer.getNotarizedData(_blockHeight);
        bytes32 mmrRootHash = bytes32(verusNotarizedData.mmrRoot);
        //check the proof and return the result
        if (mmrRootHash == mmrProof.predictedRootHash(hashedTransactions,_hashIndex,_transactionsProof)) return true;
        else return false;
    }

    function createTransactionsHash(BridgeTransaction[] memory _newTransactions) public returns(bytes32){
        bytes memory serializedTransactions = serializeTransactions(_newTransactions);
        bytes32 hashedTransactions = mmrProof.createHash(serializedTransactions,verusKey);
        return hashedTransactions;
    }
    
    function serializeTransactions(BridgeTransaction[] memory _newTransactions) public pure returns(bytes memory){
        bytes memory serializedTransactions;
        bytes memory serializedTransaction;
        for(uint i = 0; i < _newTransactions.length; i++){
            serializedTransaction = serializeTransaction(_newTransactions[i]);
            if(serializedTransactions.length > 0) serializedTransactions = concat(serializedTransaction,serializedTransaction);
            else serializedTransactions = serializedTransaction;
        }
        return serializedTransactions;
    }

    function mmrHash(bytes memory toHash,bytes memory hashKey) public returns(bytes32){
        bytes32 generatedHash = mmrProof.createHash(toHash,hashKey,false);
        return generatedHash;
    }

    function serializeTransaction(BridgeTransaction memory _sendTransaction) public pure returns(bytes memory){
        bytes memory serializedTransaction = abi.encodePacked(_sendTransaction.targetAddress,_sendTransaction.tokenName,_sendTransaction.tokenAmount);
        return serializedTransaction;
    }

    function getTokenAddress(string memory tokenName) public view returns(address){
        return tokenManager.getTokenAddress(tokenName);
    }

    function getTokenName(address tokenAddress) public view returns(string memory){
        return tokenManager.getTokenName(tokenAddress);
    }
    


    /** bytes concat helper function */
    function concat(bytes memory self, bytes memory other) public pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        
        (uint256 src, uint256 srcLen) = Memory.fromBytes(self);
        (uint256 src2, uint256 src2Len) = Memory.fromBytes(other);
        (uint256 dest,) = Memory.fromBytes(ret);
        uint256 dest2 = dest + src2Len;
        Memory.copy(src, dest, srcLen);
        Memory.copy(src2, dest2, src2Len);
     return ret;
    }

}
