// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Groth16Verifier {
    // Scalar field size
    uint256 constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax  = 17922522738663902115117377377982546569645589916258781359614940213559521337740;
    uint256 constant alphay  = 14740734263217839637573120881664842776356816571424970874575900781164523221181;
    uint256 constant betax1  = 5278873427941912624128889387859266618662347225180333328912288126360251507135;
    uint256 constant betax2  = 917272575500959667900521150316536678534830131103465904787680477675371433178;
    uint256 constant betay1  = 14527940352733074586905800962684936118698189610065003659367554377272063336553;
    uint256 constant betay2  = 3012380218700810341236716024685650720895952020775664922684381318641806519826;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 12156907784457618789087671452875914035797722125314876939014719406134401636941;
    uint256 constant deltax2 = 11479977980415639627121008739421774033629960126980052310646598487426041998971;
    uint256 constant deltay1 = 9201997241237491891358920185801537408548638682324961347567174412468690848690;
    uint256 constant deltay2 = 12951799540054026151593093506395949039896841833747987681461165552633461471077;

    
    uint256 constant IC0x = 10104683986211269066363795964811025877049089836733516296201912229931930219381;
    uint256 constant IC0y = 14156733506169638403231118216190407806049629582893836760451286252226334623577;
    
    uint256 constant IC1x = 9677986105848742138525835800573827627900600395762263875246326779798820510991;
    uint256 constant IC1y = 16376083339587160120069626148826926004656106673308569853687227560572724293985;
    
    uint256 constant IC2x = 19568003932274152050836906610275371248871529243914471448240746658294061498991;
    uint256 constant IC2y = 18045494714185605391083525926869792856122528349262753144664149733672485430963;
    
    uint256 constant IC3x = 17856912208493087655829395028003844986539119003895884774254928782994704653681;
    uint256 constant IC3y = 2679717975582597158805286721327695400132932807256379354186183356568957201158;
    
    uint256 constant IC4x = 3018445504557134402176911927666744114353948992452574570369275087244605534803;
    uint256 constant IC4y = 14222823987761718382141779478509965168269320091619621536590144157310132762720;
    
    uint256 constant IC5x = 2785950869819019762995395051945463248410098653531707252852653564907351047969;
    uint256 constant IC5y = 8496470149981375333583765703360511300477260345617344915975748169329311032868;
    
    uint256 constant IC6x = 12829522015415372374076666915386769213665228466300070897065710597253564949812;
    uint256 constant IC6y = 9308235092467212039314812734703871625968120602134172534730437371975770862330;
    
    uint256 constant IC7x = 11636015533126546723038113508799221904065090423862369122160079824451007632423;
    uint256 constant IC7y = 19317987766187300040566759412958010256761215725397579692422557296831282400833;
    
    uint256 constant IC8x = 2697641983994757496598599791940476784872401139960943370401538052507388988185;
    uint256 constant IC8y = 15222398339120010226159377804055165884553085069424584572636216077499454123874;
    
    uint256 constant IC9x = 10232943295345296997074884546437261272392335617386194289610971325617915642441;
    uint256 constant IC9y = 13128806024321271658696284156649577369053085028177195686546323433061813902335;
    
    uint256 constant IC10x = 13321872034409092825894475241465054080739400791848308381694209366598556727239;
    uint256 constant IC10y = 11802554544552522578186135624088488918152274470175949224266822385914758197810;
    
    uint256 constant IC11x = 19057935740521618595916188526201536987037329252188051622687912710588449300586;
    uint256 constant IC11y = 21410662973344687531008005360944355931049718840324701641105593797935739210903;
    
    uint256 constant IC12x = 20777561689087340777730979931866498478555001903836723885017196833248171692676;
    uint256 constant IC12y = 15125561563912550739791453614077220431846771635873985695759552539838659824850;
    
    uint256 constant IC13x = 12767306696395876264348376817753537485913249279172778971773516011892012678530;
    uint256 constant IC13y = 16324351302614246972850001682852671136152707687146016873671779731435198784138;
    
    uint256 constant IC14x = 11599750703379665763915753722594539727856823640623375029106535622995074137290;
    uint256 constant IC14y = 2748311502901605872214108030358825366598619770910492087160655125787462804403;
    
    uint256 constant IC15x = 13303805230498383307126867665035302097069962713189429837687371474536327255150;
    uint256 constant IC15y = 19079981392434270505530042400131538977056085139246911526182423434985322289783;
    
    uint256 constant IC16x = 7755904556363620364573470428280270057424916675654195376144599137711318081562;
    uint256 constant IC16y = 8249325634854867704948033143234166054833328198085432505395022981351744083483;
    
    uint256 constant IC17x = 18520582515765352357126807608961748094089626985685925230270669383670980705859;
    uint256 constant IC17y = 20197603291079037852059073396544179986026363348553773096669845148557038683618;
    
    uint256 constant IC18x = 5085770786161214892710424415837442760849465707692794887847084879818053515612;
    uint256 constant IC18y = 11926275392803103583372309816213060170999173029123826714961456967933368473913;
    
    uint256 constant IC19x = 16143647002722902536529377327548534512484472824391301545900980660232083513789;
    uint256 constant IC19y = 12045833662438436994592858456086534163777373932909711776746645715029497806730;
    
    uint256 constant IC20x = 18852411317472540660063152234269298970436118379925393887510910270477429711299;
    uint256 constant IC20y = 8520938084281357327950070695257437636609479731869537923565545799428136400717;
    
    uint256 constant IC21x = 21674939037496397740436581941487575826429063022638287532613242716886983241469;
    uint256 constant IC21y = 11392877639825668079330137021971790889133317774747003996681977536367889539181;
    
    uint256 constant IC22x = 1388916899217909788824121276075189132576392178899385514102958977026242863763;
    uint256 constant IC22y = 18311519432362699324601841254408640591178102343859978104882689068219807100339;
    
    uint256 constant IC23x = 5618821411538890805283354250774473093477793742183258418505848841813617516199;
    uint256 constant IC23y = 6950183327938006419509728327240048205489677307874433686712624188709116809096;
    
    uint256 constant IC24x = 21078202864810362813030362521489096327736524168178801000023305007991534077669;
    uint256 constant IC24y = 2823764684939316671761124561994028928907861812354480146632112450480110313504;
    
    uint256 constant IC25x = 4313709232669504627267623318929119875857922765677131500376509770311358706204;
    uint256 constant IC25y = 2191795902472472976244197382888147235507548881643286396975883687785451328442;
    
    uint256 constant IC26x = 7682307955278505528021973005395478609388618963464174540905696462693851674214;
    uint256 constant IC26y = 9239552986907758527405187398756059931834931706143372596698598265333180093995;
    
    uint256 constant IC27x = 2310954951376507092262370964386168502830927822069240470762196264750028122809;
    uint256 constant IC27y = 5768141367601385991467329521424024288261026281337230863837746056248123052470;
    
    uint256 constant IC28x = 7423942579934437659881961541868067906132917442934965650416562283412293801156;
    uint256 constant IC28y = 546831296129981659403141079147022696040316421927065733305471225162526353948;
    
    uint256 constant IC29x = 17630767754629572312744590292558001120701502243808055740606940307366869962369;
    uint256 constant IC29y = 7417170249486670594257689479737426085780120459170894473901731208109596535612;
    
    uint256 constant IC30x = 2672391600344663459676437884988886909857663408603958990160032254195634296699;
    uint256 constant IC30y = 1234393496978309500908287583580636159851248993164331969430635014912244491756;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[30] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                
                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))
                
                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))
                
                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))
                
                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))
                
                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))
                
                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))
                
                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))
                
                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))
                
                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))
                
                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))
                
                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))
                
                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))
                
                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))
                
                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))
                
                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))
                
                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))
                
                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))
                
                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))
                
                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))
                
                g1_mulAccC(_pVk, IC25x, IC25y, calldataload(add(pubSignals, 768)))
                
                g1_mulAccC(_pVk, IC26x, IC26y, calldataload(add(pubSignals, 800)))
                
                g1_mulAccC(_pVk, IC27x, IC27y, calldataload(add(pubSignals, 832)))
                
                g1_mulAccC(_pVk, IC28x, IC28y, calldataload(add(pubSignals, 864)))
                
                g1_mulAccC(_pVk, IC29x, IC29y, calldataload(add(pubSignals, 896)))
                
                g1_mulAccC(_pVk, IC30x, IC30y, calldataload(add(pubSignals, 928)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            
            checkField(calldataload(add(_pubSignals, 160)))
            
            checkField(calldataload(add(_pubSignals, 192)))
            
            checkField(calldataload(add(_pubSignals, 224)))
            
            checkField(calldataload(add(_pubSignals, 256)))
            
            checkField(calldataload(add(_pubSignals, 288)))
            
            checkField(calldataload(add(_pubSignals, 320)))
            
            checkField(calldataload(add(_pubSignals, 352)))
            
            checkField(calldataload(add(_pubSignals, 384)))
            
            checkField(calldataload(add(_pubSignals, 416)))
            
            checkField(calldataload(add(_pubSignals, 448)))
            
            checkField(calldataload(add(_pubSignals, 480)))
            
            checkField(calldataload(add(_pubSignals, 512)))
            
            checkField(calldataload(add(_pubSignals, 544)))
            
            checkField(calldataload(add(_pubSignals, 576)))
            
            checkField(calldataload(add(_pubSignals, 608)))
            
            checkField(calldataload(add(_pubSignals, 640)))
            
            checkField(calldataload(add(_pubSignals, 672)))
            
            checkField(calldataload(add(_pubSignals, 704)))
            
            checkField(calldataload(add(_pubSignals, 736)))
            
            checkField(calldataload(add(_pubSignals, 768)))
            
            checkField(calldataload(add(_pubSignals, 800)))
            
            checkField(calldataload(add(_pubSignals, 832)))
            
            checkField(calldataload(add(_pubSignals, 864)))
            
            checkField(calldataload(add(_pubSignals, 896)))
            
            checkField(calldataload(add(_pubSignals, 928)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
