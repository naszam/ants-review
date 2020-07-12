/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.11;

///@title Ants-Review
///@author Nazzareno Massari @naszam
///@notice Ants-Review ERC20 Token
///@dev All function calls are currently implemented without side effects through TDD approach
///@dev OpenZeppelin library is used for secure contract development

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";


contract ANTS is Ownable, ERC20PresetMinterPauser {

  constructor()
  ERC20PresetMinterPauser("Ants-Review", "ANTS")
  public {

  }

}
