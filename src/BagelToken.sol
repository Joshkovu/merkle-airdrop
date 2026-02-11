// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BagelToken is ERC20, Ownable {
    constructor() ERC20("Bagel Token", "BGL") Ownable(msg.sender) {}

    function mint(address _to, uint256 _amount) external onlyOwner {
        super._mint(_to, _amount);
    }
}
