// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    IERC20 usdt = IERC20(address(0xB404c51BBC10dcBE948077F18a4B8E553D160084));
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;
    IUniswapV2Router02 public uniswapRouter;
    address private TetherRop = 0xB404c51BBC10dcBE948077F18a4B8E553D160084 ;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private COYtoSend;

    constructor(string memory name_, string memory symbol_) {   
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        _name = name_;
        _symbol = symbol_;
    }

    function getPathForETHtoTeth() private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = uniswapRouter.WETH();
    path[1] = TetherRop;
    return path;
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
  
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
  
    function stockcheck() public view returns (uint256) {
        return _balances[address(this)];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount >= 1000, "Amount must 1000 or larger (smallest denomination).");
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 tethDep = 0;
        uint256 retTeth;
        uint256 retTethrate;
        
        if (sender == address(this))
            tethDep = amount;
        
        
        uint256 Rate = getRate(tethDep);
        
        COYtoSend = amount;
    
        if (sender == address(this))
            // Means this is an ETH to Tether to COY transfer
            COYtoSend = ( amount * 1000 ) / Rate;
            require(COYtoSend >= 1000, "Must send enough ETH for at least 1000 (smallest denom.) after Rate");
            

        //Calculate amount to send and fee to add to reserve
        uint256 feeamount = COYtoSend / 1000;
        uint256 amtTosend = COYtoSend - feeamount;

        //Update balances
        _balances[sender] = senderBalance - COYtoSend;
        _balances[address(this)] += feeamount;
        _balances[recipient] += amtTosend;

        //Check if transfer was to redeem COY and if so send USDT
        if (recipient == address(this))
            retTethrate = ( amount * 1000 ) / (totalSupply() - stockcheck());
            retTeth = (USDTbal() * retTethrate) / 1000;
            USDTtrans(msg.sender, retTeth);

        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function USDTtrans(address _TethTo, uint256 TethAmt) private {
        usdt.transfer(_TethTo, TethAmt);
    }

    function USDTbal() public view returns (uint256) {
        uint256 TethBal = usdt.balanceOf(address(this));
        return TethBal;
    }

    function getRate(uint256 tethSwapAmt) public view returns (uint256) {
        
        uint256 Teth_Bal = 1000 * (USDTbal() - tethSwapAmt);
        uint256 inCirc = totalSupply() - stockcheck();
        uint256 Rate;

        // Assigning a value to Rate twice like this is sloppy - Need to fix!!! If, else statement was screwy
        Rate = 1001;
        if (Teth_Bal > 0)
            if (inCirc > 0)
                Rate = (Teth_Bal / inCirc) + 1;
        return Rate;
    }

    function ethbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    receive() external payable {
        uint256 _ETHin = msg.value;
        // Make sure at least 1000 wei was sent
        require(_ETHin >= 1000, "Must send at least 1000 wei");
        uint dline = block.timestamp + 15; // using 'now' for convenience, for mainnet pass deadline from frontend!
        address[] memory TethPath = new address[](2);
        TethPath = getPathForETHtoTeth();
        uint AmtTeth = uniswapRouter.getAmountsOut(_ETHin, TethPath)[1];
        uint[] memory Tethback = uniswapRouter.swapExactETHForTokens{value : msg.value}(AmtTeth, TethPath, address(this), dline);
        require(Tethback[1] > 0, "Swap did not happen as planned");
        _transfer(address(this), msg.sender, Tethback[1]);
    }
}