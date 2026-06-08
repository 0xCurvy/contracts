// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.28;

uint256 constant BATCH_SIZE = 5;
uint256 constant TREE_DEPTH = 30;

library PendingNotesCommitmentFixtures {    
    struct Input {
        uint256 inputHash;
        uint256[BATCH_SIZE] noteAmounts;
        uint256[BATCH_SIZE] noteTokens;
        uint256[BATCH_SIZE] noteOwnerHashes;
        uint256[BATCH_SIZE] noteIds;
        uint256 currentNotesRoot;
        uint256 newNotesRoot;
        uint256 currentNoteIndex;
        uint256 newNoteIndex;
        uint256[2] proof_a;
        uint256[2][2] proof_b;
        uint256[2] proof_c;
        uint256[1] public_signals;
    }

    function input() internal pure returns (Input memory) {
        return Input({
            inputHash: 69143606117807069827363780831789018146287388910679959957128154935265278418451,
            noteAmounts: [ uint256(100), uint256(100), uint256(0), uint256(0), uint256(0)],
            noteTokens: [ uint256(1), uint256(1), uint256(0), uint256(0), uint256(0)],
            noteOwnerHashes: [6857938775075341135658035410901809884772724134719627345490001914926449216994, 14493063707459346251940050901045813830646587194915566525829554826324561100453, 0, 0, 0],
            noteIds: [8538355061771102328094297037735751701044086734679632728822999775202679288444, 14085954852295498940027993368375581284492420361889230594660973727337646007034, 0, 0, 0],
            currentNotesRoot: 4114686047564160449611603615418567457008101555090703535405891656262658644463,
            newNotesRoot: 2870193367367118306412514110691501670534365584237996499498864672069976524625,
            currentNoteIndex: 0,
            newNoteIndex: 2,
            proof_a: [
                0x2f862569448367e768b95c311432d338389c183247350fbd10ee1652f665e619, 
                0x25c82b2e9a4b64dcb24d71b083931bf9c2224024f55f211e983e9517d5c47720
            ],
            proof_b: [[
                0x02a98a2c608a24c4cabe782eed9aa91bb026473164893b82f86c09e244616376, 
                0x21b0ad02948e63a43eec8e49e3b3da3e2f076f82e1bffc051497375a74323651
            ],
            [
                0x1c167a0d39c789cd406419dda7c43b000e544cf9b83d7712c9de6f321055b673,
                0x19e7319a924726a44e0872fed593379db4fbb97856bb9343995d95d0d77ec3f9
            ]],
            proof_c: [
                0x2d8242cbccd43b821cd6aeb9b290bcdec738d2fe154bbeb9a9a3d493baeba7b6,
                0x267734d20708acc16c9a9e7a353b21372991032aaec8279650b306bdb3729bd1
            ],
            public_signals: [0x07b0f9924a2fe98a20b5bda2fb864c039b2db3a48a3b9f93126ed8179f39de10]
        });
    }
}