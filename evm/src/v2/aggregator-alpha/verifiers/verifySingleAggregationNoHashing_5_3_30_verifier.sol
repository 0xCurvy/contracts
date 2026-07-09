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
    uint256 constant alphax  = 13609597477422817544806719940578211239660138492812767741570640666225907996628;
    uint256 constant alphay  = 3315096884673693139303582008970220799715870802021815302955257248960229394132;
    uint256 constant betax1  = 20244502790401697640374985581353359627000854646412500262318694555628864857705;
    uint256 constant betax2  = 18009540316062949354047865494362899064185820891461168067970621853171214969025;
    uint256 constant betay1  = 21485324237153900776296822920524193097954549703233921348239585839570605636041;
    uint256 constant betay2  = 18873349741553391434573540024886497503852362769056818998084383144689457732005;
    uint256 constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 = 3065866860674254189411279004081887163627579006353133446515109459464949976111;
    uint256 constant deltax2 = 16475050043685358092662553601321925018765637498149729159609078707011513644662;
    uint256 constant deltay1 = 16113260464683434115743001943473086500692681371751670432464295057189074779878;
    uint256 constant deltay2 = 792307467615481011797550428052658632781944309880582703489972506399555496776;

    
    uint256 constant IC0x = 4972888151877631523323389103339445962302170406646771686666966632125442216152;
    uint256 constant IC0y = 11614940634046463312854142817876163827715515233111040986807445223870625649313;
    
    uint256 constant IC1x = 20248811902436225615342920020584728447306459976349707191695516700276460965828;
    uint256 constant IC1y = 1747774242443489153960535757482554226285632405407385760521904453132554971166;
    
    uint256 constant IC2x = 13349134262822714617972115902964166802738618234877927136336079492857956062683;
    uint256 constant IC2y = 2191517571299634440277106704544703366725282217617842319195337216156251900921;
    
    uint256 constant IC3x = 12129642049237629940429039349925961198241918694189971729735638228434093419429;
    uint256 constant IC3y = 6620507629205491433411894186716621002020536313970418118839255611682911055884;
    
    uint256 constant IC4x = 1393204407604954752338470433265129038951610438711828185437509687066858521239;
    uint256 constant IC4y = 17560598163158550935538607066811089706080533931371128124483581516801225260636;
    
    uint256 constant IC5x = 7842539247523345171270305480076976431025812876306839625485295883439700299151;
    uint256 constant IC5y = 21781721731686076251035420126469038948889288342619843136389597704587195425497;
    
    uint256 constant IC6x = 11675159966225484783911275708055302869357422761170608211889009366986396648278;
    uint256 constant IC6y = 852640173823134038582999149755921560116945139543559104172571269543586565767;
    
    uint256 constant IC7x = 11325237509477503053404411293555599160788679408050966748652152163658666455177;
    uint256 constant IC7y = 8102514872151607249655177309685059156619418049206433094696162384977686045649;
    
    uint256 constant IC8x = 21510470228538841017658414931832000812067420990483021317672403011022463198005;
    uint256 constant IC8y = 19740456501061324187731901721068493512978952086506814233343042269115532069782;
    
    uint256 constant IC9x = 4219984720488642025546171945859447635819533908119928736098209209969103339054;
    uint256 constant IC9y = 9662209304983905973827847341378765322220148839613973805497455265405527084228;
    
    uint256 constant IC10x = 3095264628877688618813432932198826677664200975128040891794675243811063247432;
    uint256 constant IC10y = 8179768023053690797082915575674503616623686425297197981869096270494516117364;
    
    uint256 constant IC11x = 21188796848224847339179398429579546222331845248087445143568434241101470641153;
    uint256 constant IC11y = 7437555631968204222777745209565897615287526587161548816579579516801608945624;
    
    uint256 constant IC12x = 20354974044737743786772884594059462724547087455155125814753237794496283628154;
    uint256 constant IC12y = 18818796326326168240440416143105006071187618095053436330767217654589159509551;
    
    uint256 constant IC13x = 20753654247015041454571613626447894902400188426466018600515727744779123909831;
    uint256 constant IC13y = 19240760047271410470578448533164044620166890565695956508536785305523503178738;
    
    uint256 constant IC14x = 3863893855919315898142725690195715531633347370840509704712738280890235024717;
    uint256 constant IC14y = 14771176043714262553339285032594331263631079554795161813381900643700064317461;
    
    uint256 constant IC15x = 14510338208485138399912455458863539690233928417514667795094755767687652508337;
    uint256 constant IC15y = 18539258904990794299261920979062839527775779945876780462509917270782612467497;
    
    uint256 constant IC16x = 21302740665888934864966877713892819127169007187669680159399080610636327495744;
    uint256 constant IC16y = 21531859333131499904585543879931207940723893955788751640910637334022020382438;
    
    uint256 constant IC17x = 9631767041326246226021273241446324593152926957972556192308279686021329186256;
    uint256 constant IC17y = 19553521719116033806906599667535009836802905756863769454014559496594300416151;
    
    uint256 constant IC18x = 18007405027412239576936059184169534096578974745538077133409917779533893165268;
    uint256 constant IC18y = 19916730531815637905424299250617427482381649105914163225126821157411758083698;
    
    uint256 constant IC19x = 9040688637889957113023342672032977425331132757547266267909196285104092821623;
    uint256 constant IC19y = 1448389937719732760959510101391998688125738179578052762010732593902309407288;
    
    uint256 constant IC20x = 16859714252826506384004313699198258769193209059376449777210536998035402041160;
    uint256 constant IC20y = 5247531920612929108357516515695793110321727431505689252223820577217472419485;
    
    uint256 constant IC21x = 7118320802226514025529636996549332013647422418401139883187563461392345088917;
    uint256 constant IC21y = 1367670824063916096382630070707854268460143162852554314243642344077538831604;
    
    uint256 constant IC22x = 17958437145253412956310101769467515990370637334290621441833584985316033292104;
    uint256 constant IC22y = 14508262998430827490609419183069236032109658427448121410213199084910107231237;
    
    uint256 constant IC23x = 5264167925612345578929674707724182492313540555568868712652667693897874230788;
    uint256 constant IC23y = 8515997779686294168437005551276792892492518995896637469831470184158235263421;
    
    uint256 constant IC24x = 2190611170543737497854900113583242477833604495552597344750401522987597725416;
    uint256 constant IC24y = 13476546992337946437404974621520238588012641001699044947738072093854632103114;
    
    uint256 constant IC25x = 19478990952831888441178898905174957477190290756139694077304034655182730180796;
    uint256 constant IC25y = 20807191391562589815855771892606797154378802541307820550653938318859241812921;
    
    uint256 constant IC26x = 19082094889969475769118106621186418617857530147208580492924450204315991437795;
    uint256 constant IC26y = 18627199215235983739396249783261800354011077023816651253850064122088888968663;
    
    uint256 constant IC27x = 3401671402545301480941548893636763982182634688566040036590831635252964619170;
    uint256 constant IC27y = 13097650356959315535197563958018439550011185209905635627610303705718960191101;
    
    uint256 constant IC28x = 16245588027866873101536609650734295028165608933427028571886855038816926441930;
    uint256 constant IC28y = 1152193553467556253255510063656099697376572528537673909028457527179731754019;
    
    uint256 constant IC29x = 7199942352423501801890486417620584105839732045209469473506448512379577827713;
    uint256 constant IC29y = 12224955353720668460422900367300031503113149283917979643280120378275379587641;
    
    uint256 constant IC30x = 4479786317273736709030802526133856403768580521318122651699467507159095758614;
    uint256 constant IC30y = 5752513408954009695876737772669011607863572484846525703852531002113963015079;
    
    uint256 constant IC31x = 1303850204165215675220728195456081261465195281237246692544182398343214098762;
    uint256 constant IC31y = 11875216691066227850475990122556419427129007195831832958973777172478984977923;
    
    uint256 constant IC32x = 15845703064534188524084491261436395969647736342597179503098097895338936520721;
    uint256 constant IC32y = 10542647660962211259265368201645329803467458686601197788559878857065234666774;
    
    uint256 constant IC33x = 3645405621707963657602395913293669750459648194722878851860704335312160949830;
    uint256 constant IC33y = 18784953837841635021398407541765417751521626387002302237438337792610958747977;
    
    uint256 constant IC34x = 6970940512316824829823589537575149183046931671088967931132132124765751939784;
    uint256 constant IC34y = 21520772022275962725734831430723486260599511864703342726120934578955405301072;
    
 
    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[34] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC32x, IC32y, calldataload(add(pubSignals, 992)))
                
                g1_mulAccC(_pVk, IC33x, IC33y, calldataload(add(pubSignals, 1024)))
                
                g1_mulAccC(_pVk, IC34x, IC34y, calldataload(add(pubSignals, 1056)))
                

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
            
            checkField(calldataload(add(_pubSignals, 992)))
            
            checkField(calldataload(add(_pubSignals, 1024)))
            
            checkField(calldataload(add(_pubSignals, 1056)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
