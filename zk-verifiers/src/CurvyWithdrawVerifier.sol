//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract CurvyWithdrawVerifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            16428432848801857252194528405604668803277877773566238944394625302971855135431,
            16846502678714586896801519656441059708016666274385668027902869494772365009666
        );

        vk.beta2 = Pairing.G2Point(
            [3182164110458002340215786955198810119980427837186618912744689678939861918171,
             16348171800823588416173124589066524623406261996681292662100840445103873053252],
            [4920802715848186258981584729175884379674325733638798907835771393452862684714,
             19687132236965066906216944365591810874384658708175106803089633851114028275753]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [19802301467903870883751399601337468094809998643237391779104092727108107625320,
             10860333325396158884792445874737862479885355621747777533071212810650180231880],
            [1938037000238029018393646674253237992532708282357604027340605215328698292291,
             7650912705751916027339838721250858350033305604095692654837701751958361354687]
        );
        vk.IC = new Pairing.G1Point[](24);
        
        vk.IC[0] = Pairing.G1Point( 
            1130720769626251138352091035078372035904082941153360001299234237045742023281,
            12625128684144822259410631865906577753671408398608464937794961986893249799627
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            183690789842591966811339160572683490322903511984513179488082906624837208909,
            2349968133782753324988431296896132082074759437066759794373630581101023411419
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16381510102165706652290544984225670755605813739864447172017107138701734797793,
            16789485699686539727858153509978166225824484187774106983413572224298297187635
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            1866093646214552914429312588179101446985039742546006221286567071944764400378,
            11807024265287247156199267425693220456326234165581349320305561196708177376827
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            1869246899112769673303025672171425387649625794827511195993215867680176910634,
            19599853255417181315290047019679399901111780216563555994104805153124640823206
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            3045013846586801134145140525053380507025354935250072640715888284428232153180,
            8796110947702354312944837514568424669771901536795639749949808038876860038324
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            7004977324029788458914066187321760729028925884754217470100529458984504148807,
            18659426806138916358056325680834969677575270242592422926806296345444344166521
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            18267029066784419600887073300447916912282884750199891788527189434487823383002,
            15575487774593861762047634708088805615842563993187812493287192806851755253203
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            21296656765340198543104024376369403762235927397583483753688343753252175647847,
            15386545728548865765078366453853856368047821230521639971414284615807632617804
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            19189692845241889758861031906741147585908286516788317362410567386155881770729,
            21383077143058200694312499433294164620656389445188655282865432918422189713657
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            3801977502552467740739284867674697135933201822463457750702689380795448003301,
            1021087726689283948008369737121618806463661198556866155997698210371360070756
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            7507343320066657517856450072179648926555233523971773576037279425199010846658,
            18672427877769185703221609877374548425419811448219224834544956318121781794684
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            5802301024172508488331782710653117509196455383550744076736157618531174820868,
            1606380892983389084471669953512109875041840784762996829639128751928881303796
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            5963985191602652444989109109757254735183978537049277912617751515742863591805,
            10907055238812640457153502876170694899970531351235909035855555571176170796243
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            496619160223694055056417486307546111091972901218444657551104726337258390061,
            20491066692617987390646267993286634509115682764245444721967981604431728247870
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20198951139521116851133420987413241039028861023677666773468167379638675145926,
            15837180028551236368350340115576117142911970261928998110715383908345380568402
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            11154061916660627109431269457765180036058256760950699915653156829220742870064,
            6456678053002916154915171886612319452627670060928403402627942889932413010807
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            12342595259346339188211039162461998963102284958308213482535629198598175656686,
            9247852389900925947783166939534625734679895959853369537095667256167194674954
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            3838763520552715894521800822564290577643840422044875299988768368757611399481,
            7807350427869118540276444328718276726082556260724741520406368982754357181937
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            10337051987859370917447954592558492802594668008421260760201711847258328297497,
            11126465360052143877368537406362022506180756370704369888554365489099626684243
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            11785241068009449715880658933153320768296961075883310778209326962026022199929,
            5500627862985913972439563530128983052663928264127145354583169392807264038819
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            7353786268501429248616444678432082085651437088146202720953592777993309801914,
            10834068448612632316676825554911136474959922489483141873230924739774266339584
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            3450425838830943600748963663350797459276414769007736170206759795212424766238,
            17062979227616681314250508782004142625640553157730628012901185571058264360213
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            16475156898175057564194947605088469543939665878007839628862102697631028651318,
            7321506520055934903519435979651253916940531310966625115572832761107677729593
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[23] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
