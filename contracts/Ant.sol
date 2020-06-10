/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.9;

///@title AntsReview
///@author Nazzareno Massari
///@notice Ant ERC20 Token
///@dev All function calls are currently implemented without side effecs through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";


contract Ant is ERC20PresetMinterPauser {

  constructor()
  ERC20PresetMinterPauser("Ant", "ANT")
  public {

  }

}
