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
contract CurvyAggregationVerifier {
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
            [9450634584198455546882815621758993989460173475062520639966065327353478837712,
             20015987206437528814924891582108342950423813823389082976025782564530548973328],
            [16558179190632636955215084902724255869134727959331524574226638035052291321226,
             20472744588671709395482397518003045169056060761266323060736652816960802539120]
        );
        vk.IC = new Pairing.G1Point[](47);
        
        vk.IC[0] = Pairing.G1Point( 
            12575135339398593627963454573350929592905397181371065423841636179859724799236,
            3139995673681827718130021807504654798249500007817452596633305883661960191616
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            21627987065585731392560134291023703192236708504066303390646591286145479010136,
            1474346466507250321993683851239068436730807505441896174737544495778719354906
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            20495714225018365789464745216815916618651681471731983207481277312723003420108,
            12884623253861913843754334005053139741811256847216227600029148091713338787536
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            17661290871888364499978088152725203111837456009946019773025977407721729733718,
            13844513838749987795537264450173737737564450710039088552659568647190188959878
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            3136201662199237468918486518485306986178501609909843671768135646440406379195,
            6818625708240338395900998379305609678626181816398708544758385016817565815273
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            7165548257863620857242831893518682893703604821014439940445997006657774782986,
            8780390556083442048536882481522457688465238490080606647828730732610340290802
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            18509080361841763504997247837450722017816948953046151525288128606910132168294,
            13737793161550993904666566279232143997748807882114349799811398249501424702458
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            994489626637311806826823664583086091825051840146299366547514462326169476156,
            21213259848112808927625563721690101286322334995319605569124364296073712231148
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            7470172089695555389525707702830982190343761701916789550435306065275802697238,
            7807209943566871097196340918926208001877010326183430098514248719867938456695
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            16514261952626775051538189423219031546708389903908749365059606831493383527970,
            15926119721527060955069006275667643325495749591527216233494456752254222428524
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            9219813219357537408819254924059395617432152317328156718493971252097206601670,
            3182759640340855564977442349750989335031783170303907833790492735658840293362
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            15683548964412138787390204577678560284508952424957886784727868001592530199444,
            7055336517133738878618727633738259193654526383817963503710025641104331751271
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            13956673183831334715669534268865530207003885204502499515603160875116786396472,
            12167029683742954002420220605864369081664807706843414051399634411061508368711
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            14500383063233150978758415157543822659743164392546523817201695071223044382647,
            11836327814339485685969805119801129064349019429025052800190116395782486748252
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            9152124556269146679936407530926790145857608596462788912941101779352697786352,
            6356137095238367384329676822449951934575934489517563590402063398439521585767
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            1139421825110277134561828457023027790938888596034003852296085749817455452799,
            9948024950242048225077828641500537940169077171594076906687355579174669412736
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            6922007461481726983066603377026355926242666624398073379589486322711349750420,
            3521225117433095771383662559614476345342811337973228694041390458345936752432
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            19494405178100876941565271353741402850072010487263026082028796389508351413596,
            15465774276951187961636730602847727367877342645471713661198125968873274478584
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            1624771768297681542718587815588012727704827544022157338333178614355106283210,
            18895341073772320215984362463967964947048627810026389692382108662720776925846
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            12021915042133071973404528749022506603327844764507995514602164874133668505980,
            10664760790582266283654107646084385711671590695400324537044356003420149794070
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            13351920467704622277404567678576615912720419223173510289671962261406270775718,
            5885203935376289853927025197931436250560028249211259634096884135890002586829
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            15092959471233409190688002111216656885264777574150318528351005840752081921324,
            11938931945676426409942928345193440339152494533332509631472637500475255498766
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            21274616366203993666199265476882858558472609148951547692784460560582928098066,
            7118503438833427922894200086043925665756413195223592771381381950210189548776
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            9116935455966884468673390751210922760638443029769077689357582852035247216291,
            13183959995581359673161378762332651392304172809272833807252738807070234770163
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            21773847281848822266287332345872489716035555757826599591083857221262893169765,
            20058101893964582371447728922005873913165513346455923325614493376333239521801
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            9040542993872120652649348151556265248529882170772941454349248684871039601444,
            19470724699107026749275081581863108104549736938905758029348789063150841465715
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            3592784783082792127766102794899380039885034389320892962715117416300627003343,
            7027880997061730298889816830761630813847178570532842426895356261633567457147
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            3974400203697430269926625862940946240520869521170240219360428404880760870554,
            20911898191532536666115481277269813372221150128903352597205136930737336302460
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            11694565288525770118558639583950815691799667671293552251632373817180476545228,
            18855943924389334278794389088209448254649737919857118232022743793739216666834
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            19256895669196396945357905477937191028896736897468473286629486007772472650766,
            7748182152951695690812344763071220852034979099161752145532477540602578494145
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            5743643854957571353180334489948542637726794054185985579971583938002350720128,
            13843115931778165199525304651141898946928404388986945901546894055421636335488
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            17390056374040336458084718085194663368829808043087931446315877794458441149064,
            15713619981811096436532802948261990623629371494140090142633085546564131294494
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            13014707220593364857837681487938806482510846393836125321518567198809694963307,
            10361204778581480154209962388888085769293191832250118417806765353555891208295
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            17406675235970693403394948188378680759577912611155219502450503793461918691818,
            12859809972381051449517103100803183130737362119621632185732964138920090694381
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            13088150243450529884792776485012015865444486587227862505295148689370647767530,
            11815790547041276578255276027925859626150055268093672548285425088363794541285
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            13309368162380925106601348109672722540183798604642023952649796519458489838151,
            17851255791365968708794332950220087556095529362270000529885442536390643543922
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            8535379584981946340572918776248442665989094413460130789434551135679843568709,
            9381397042325259973585719418198279260688682826911374486829996012696449960675
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            3290370211231679199074258245851843323948469642162584814036126019551728624214,
            12572267757802630021629896408559390081353592486000026328105400310879665985651
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            8637636338055545199081435753356034568287395530892288370150847832129955087039,
            763186426477275431955769343534679253867464551950648785238182914847155788808
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            1885415093947721219149707272845725903972076140506568967783178134993135312198,
            20493901223068422549905436134713516675140751202173226529014947199013561280305
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            17165575957197871110942096057617615772765670630128295545312792457384033826729,
            11989404758675123415879568127609319348937025890186173654324592162807282237893
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            21411593711708908824790173475153460512810552924214789550052767433864905096583,
            8136543570958798275828616213256632043515353334036734813996470393702376071083
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            17194924418958349107775558578336829057247469826334996654723711643627760518677,
            20659740257205574646027595349644958847610824611359036335352528498305220805780
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            4056645257939886848626957461608148980402901589887562666839550791388185671825,
            10785211151487136725814653827939682960280611593536980162196460382782060701207
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            8112107483664118887876548598289157623331361833092475897193467950054466318908,
            18267462151878509989020315691046935440653691246922009941417397280286480681657
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            4385366913636176008087961928613661599997875000441113523651796095577495043684,
            500892496507729799987907607497857844919835386120543490752695938093963737607
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            3149963609768316641226647233049451187393467210597365692652525609339835645809,
            3415437732852751987018930605192171396281233139813347415675063077947951584698
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
            uint[46] memory input
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
