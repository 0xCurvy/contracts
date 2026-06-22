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
    uint256 constant deltax1 = 10796448285813325867696876888899751551503680418213444484647620665677744541630;
    uint256 constant deltax2 = 5295250025869288455182407000639175798007881290077596899814953213342903076680;
    uint256 constant deltay1 = 695203615438374731505999761465916661572047601119687093147572727611697388326;
    uint256 constant deltay2 = 1953935861979982720230368266152130863792926203096555385331769477813515701184;

    
    uint256 constant IC0x = 466058729426773154420775700521502250361144165340846221449733106576297393459;
    uint256 constant IC0y = 4174221679112609220666594104542801738682132225707792909317462552517912799054;
    
    uint256 constant IC1x = 5077929226771403370516061460459271940698749332151532382566281793188501614993;
    uint256 constant IC1y = 18092590002648887671390644104411164570858362771108189360216369978820116483329;
    
    uint256 constant IC2x = 5864403848507674052996262648411227872021676936497900870574128012647968915163;
    uint256 constant IC2y = 4122903201956520676665027382010736080007298850627180567553546504489794184559;
    
    uint256 constant IC3x = 17515701602559728958598081691142135559178646315790915005622452180023312401415;
    uint256 constant IC3y = 15411391784318786611775117274850464253723159006752397292028869918421324386496;
    
    uint256 constant IC4x = 6352580773575361169398812441762293010241729800158502951746756587402347003612;
    uint256 constant IC4y = 15830567827086877423495325810185038262671140141822010973286467435674577579817;
    
    uint256 constant IC5x = 21209706026061746519987217795625183926632172104495334713245733696507538156014;
    uint256 constant IC5y = 19019319586805948169849696838236382368206477952307837054165589183182189672554;
    
    uint256 constant IC6x = 233629320073341875563228544409057871487256008362736905132608639190851531383;
    uint256 constant IC6y = 8240869075359401059238029974946028749105409831973863819158605332632892892196;
    
    uint256 constant IC7x = 16418378086804983603469236668163195110220389707490907898626466732397032541479;
    uint256 constant IC7y = 3091233872017895220942200452924872319706513867356221896434207254221383149897;
    
    uint256 constant IC8x = 8575077798273961048356828373542487436363740635426741735793961092628910514087;
    uint256 constant IC8y = 5555996425823884413143315383198369321767603576093760321312961538346806738417;
    
    uint256 constant IC9x = 16146017030754362241843858085755698990450689848497618705401031467414871707439;
    uint256 constant IC9y = 13649116452310707140454942400445651898170757037481239218023427857086080458357;
    
    uint256 constant IC10x = 1608242291583142292817631612449879035632007212565759865185614136311433173233;
    uint256 constant IC10y = 14170519124284348137441870380294432357860368383569699034136070866176787813382;
    
    uint256 constant IC11x = 11982371142652777672640456511820620877312932956520262457444888741052366477594;
    uint256 constant IC11y = 11944321152608713310844740178248153231658584533506180126196974855286095445425;
    
    uint256 constant IC12x = 19416375514525111925081704914793498829160020813093831890334608875682186883074;
    uint256 constant IC12y = 17274612824827716900180937151073569260635089288830693957985182381757736049113;
    
    uint256 constant IC13x = 13845179258238364788581173822323981789823366917850683914975227099735499502293;
    uint256 constant IC13y = 16803294321678503712235175408970435603265020122329966732859579615988231164005;
    
    uint256 constant IC14x = 12094307623986338983934344838019933567953431461219256991886034786737521815433;
    uint256 constant IC14y = 7841562324403127964381160880820255469471831317985164350450858471788311093222;
    
    uint256 constant IC15x = 11850215880998951156674383212750502930111158438840505522988618871089185635609;
    uint256 constant IC15y = 14111091152388029312821936144652379538657795085543056883775149145909274049352;
    
    uint256 constant IC16x = 17060021595461808251291385643945414189159785037443523703555821109869647917375;
    uint256 constant IC16y = 1774295508291836871003090665449146708169680992281377173648807612480453088575;
    
    uint256 constant IC17x = 7607149482966244662623156851952230005219059181197735831058332741389945954121;
    uint256 constant IC17y = 20838907601161806561117656152982555147377222197831904563807664993464664318421;
    
    uint256 constant IC18x = 7292936885799847728252160429063044672924318770762397525141040573149149518574;
    uint256 constant IC18y = 9563310559396410320194377291230263108223927688481040043729283903656004237093;
    
    uint256 constant IC19x = 11878873415328810163526957440769682625020207113576586845271973940670543258104;
    uint256 constant IC19y = 20717683596207248846522224105368318897075256296134926908436065840661955771394;
    
    uint256 constant IC20x = 11489450818378215620792553132233166978964926436298806669114849611929821417256;
    uint256 constant IC20y = 1228240945386842790389660686647335342796624191989318304486850949763562896057;
    
    uint256 constant IC21x = 5232888580341565068423104103520611205454617668211352299390219678328480979767;
    uint256 constant IC21y = 1078183157714940012862511452837005871451837530533928158606844724565115117617;
    
    uint256 constant IC22x = 2336684816258625522424755379178679061413696464697573065371554876306332261066;
    uint256 constant IC22y = 8318271884344439337907271195158395863546630772051580184886659715876834096380;
    
    uint256 constant IC23x = 9480858458846994609281874062479118486790624833869100674080986652285154795296;
    uint256 constant IC23y = 19042661585512945682891183591334270946286127814511260777770016151271619268800;
    
    uint256 constant IC24x = 19740402038232913338806115927680029339722371182937230109808892171524065463393;
    uint256 constant IC24y = 18414034527737305838140037245599720488106616456091712365767790792204937703299;
    
    uint256 constant IC25x = 6258923156353607059771404665879685758408153736969565869715990091871942342654;
    uint256 constant IC25y = 1869619575882938836955189126910430496246296182461063876550273787368744406785;
    
    uint256 constant IC26x = 18758374945556879280603416867120760088079154236489812613769423401009037088749;
    uint256 constant IC26y = 10642205970148357736905978705988573047607558661691966786348199468883991163953;
    
    uint256 constant IC27x = 13517667396848146381236390159571689724857845651392334088189222598720760394285;
    uint256 constant IC27y = 17785608911194522615345091550956057489316138351741155398527609763827236901335;
    
    uint256 constant IC28x = 17080906585280193205970550811422210713541997556098015946833266448084989034615;
    uint256 constant IC28y = 10057872901319678468417233875448287749869487256108500598840175494266045240595;
    
    uint256 constant IC29x = 3415830259729051365550159579322806739198912125787650367843598256543475278674;
    uint256 constant IC29y = 9463451360194722519733959303720398319267339217927633044265039712948092412382;
    
    uint256 constant IC30x = 13468361965750206235747683746947999505300517876406753723378082175256557053499;
    uint256 constant IC30y = 3168386451217014462574273682153331550848487896741630647739362534488421076279;
    
    uint256 constant IC31x = 7820425693084838698061392455071648541184211316539314515728608446004007758319;
    uint256 constant IC31y = 14546304811028810157818762516236305252646539807562330019875222521784685490419;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[31] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC31x, IC31y, calldataload(add(pubSignals, 960)))
                

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
            
            checkField(calldataload(add(_pubSignals, 960)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
