module dev::verifier {
    use sui::tx_context::{Self, TxContext};
    use std::vector::{Self, append};
    use std::debug;
    use sui::groth16::{Curve, public_proof_inputs_from_bytes, prepare_verifying_key,
    proof_points_from_bytes, verify_groth16_proof, bn254}; //pvk_from_bytes,
    use sui::hex;
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::address::{Self};
    use sui::coin::{Self};
    use sui::sui::{SUI};
    use sui::event;
    use sui::dynamic_object_field as ofield;

    // The creator bundle: these two packages often go together.
    use sui::package;
    use sui::display;

    //  public entry fun verify(proof: vector<u8>, public_1: vector<u8>, public_2: vector<u8>) {
    //     let proof_serialized = hex::decode(proof);
    //     let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19fa699e9b4686fe2e83e951ed08534d6ab5d093d542ee8fdd5e75100b3814f90c87d3f290481b05e1c7c8fc78dba5fb07466a907b7dfcc6002f77a0b49b9635ac0300000000000000b4562156b4f417c86474d80d460c8e373ced90ba3348154ff962ed73b56533291181cf9baaa5ae17c7a2a51a3799c4759154f0b4b27e7f766a360d28f628190daf527193c5e10913c6eb3f7b189b29ad878e0e097cf4ce2cceaec37a6f6e8c01";
    //     let curve: Curve = bn254();
    //     let public_inputs_serialized: vector<u8> = x"";
    //     append(&mut public_inputs_serialized, hex::decode(public_1));
    //     append(&mut public_inputs_serialized, hex::decode(public_2));
    //     //let proof_serialized: vector<u8> = x"887cca600d0c168ad9a4db59ac8aaeb1519bc821a0af0b5df7e459eb82660c152d1bbc390bf3b03155a8530ede05265d8c8574aece938c9d54f6950993891f7808d694c4352ef93dd1bb59e272a383e4a07c4e60a5d847f6b395dc24a00b59c5173b7a96843a2c5d1516b0ba68c96829f1a02e005dcb4d41406088a8b5d4deac527ff89db2ddc497414bdb35c229a7c786b7678ce2d5e23de57634f84567cb55b651cb5ee4910473965e2fd60755d6c89314add6024d59ea737e5bc769f9c3a8";
        

    
    //     let pvk = prepare_verifying_key(&curve, &vk_serialized);
        
    //     let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
    //     let proof_points =  proof_points_from_bytes(proof_serialized);

    //     let verification_result: bool = verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points);
        
    //     //let a: u64 = 64;
    //     assert!(verification_result, 1337);
    // }

    //Shared object Map
    //Quest_id - would be kP_x, kP_y
    struct ProfessorNFT has key, store{
        id: UID,
        name: String,
        description: String,
        url: Url,
    }

    struct WrongAnswerNFT has key, store{
        id: UID,
    }

    struct Answer has store, drop{
        student_a_hash: vector<u8>, 
        student_aH_x: vector<u8>,   
        student_aH_y: vector<u8>,   
        timestamp_answered: vector<u8>, //Deal with it later
        student_address: address,
        akP_x: vector<u8>,          
        akP_y: vector<u8>,
    }

    struct Quest has key, store{
        id: UID,
        question: String,
        professor_address: address,
        professor_k_hash: vector<u8>,
        professor_kP_x: vector<u8>,
        professor_kP_y: vector<u8>,
        //answers: Table<address, Answer>,
    }

    const EInvalidCommitment: u64 = 0;
    const EInvalidUnlock: u64 = 1;
    const EAnotherProfessor: u64 = 2;
    const EStudentNoAnswer: u64 = 3;
    const EProfessorBadMultiplication: u64 = 4;
    const EStudentBadMultiplication: u64 = 5;
    const EAlreadyAnswered: u64 = 6;

    //Deal with timestamps later, when all proofs are working
    //And js client for student, and for professor works right

    public entry fun professor_create_quest(question: vector<u8>, proof:vector<u8>, professor_k_hash: vector<u8>,
        professor_kP_x: vector<u8>, professor_kP_y: vector<u8>, ctx: &mut TxContext)
    {
        let professor_address = tx_context::sender(ctx);
        //professor_addr_serialized with first byte (least significant) flushed to make it fit 253-bit curve base field
        let professor_addr_serialized = address::to_bytes(professor_address);
        let last_byte = vector::borrow_mut(&mut professor_addr_serialized, 31);
        *last_byte = 0;

         debug::print(&professor_addr_serialized);

        //Immediately asserts that professot commitment is valid
        //(He used this hashed k to multiply by private input P and got public kP_x, kP_y)
        let is_valid : bool = commit(proof, professor_k_hash, professor_kP_x, professor_kP_y, professor_addr_serialized);
        assert!(is_valid, EInvalidCommitment);

        //Only then creates a shared object - quest
        //Writes question text, k_hash, kP_x, kP_y
        //Auto write professor address
        let quest = Quest {
            id: object::new(ctx),
            question: string::utf8(question),
            professor_address,
            professor_k_hash,
            professor_kP_x,
            professor_kP_y,
        };
        let tab: Table<address, Answer> = table::new(ctx);
        ofield::add(&mut quest.id, b"answers", tab);
        transfer::share_object(quest)   
    }

    const EInsufficientCollateral: u64  = 7;
    const EStudentInvalidCommitment: u64 = 8;
    const MIST_PER_SUI: u64 = 1_000_000_000;

    struct StudentAnsweredEvent has copy, drop {
        timestamp_answered: vector<u8>, //Deal with it later
        student_address: address,
        akP_x: vector<u8>,          
        akP_y: vector<u8>,
        student_aH_x: vector<u8>,
        student_aH_y: vector<u8>,
    }

    public entry fun student_answer_question(shared_quest: &mut Quest, c: coin::Coin<SUI>, proof_commit: vector<u8>,
     student_a_hash: vector<u8>, student_aH_x: vector<u8>, student_aH_y: vector<u8>, 
     proof_unlock: vector<u8>, akP_x: vector<u8>, akP_y: vector<u8>, ctx: &TxContext)
    {
        let student_address = tx_context::sender(ctx);
        let Quest {id: _, question: _, professor_address, professor_k_hash: _,
            professor_kP_x, professor_kP_y} = shared_quest;

        let answers = ofield::borrow_mut<vector<u8>, Table<address, Answer>>(&mut shared_quest.id, b"answers");

        //Take 1 SUI for the mint anyway
        //Send it to professor address, retrieved for Quest object
        //!!!Enable mimimal collateral during production!!!
        
        assert!(coin::value(&c) > MIST_PER_SUI / 10_000_000, EInsufficientCollateral);
        transfer::public_transfer(c, *professor_address);

        //Check that I did not answer already i.e Answers map does not have caller address key
        let has_place = !table::contains(answers, student_address);
        //Enable in production, disabled just to quickly test event subscription
        assert!(has_place, EStudentNoAnswer);

        //student_addr_serialized with first byte (least significant) flushed to make it fit 253-bit curve base field
        let student_addr_serialized = address::to_bytes(student_address);
        let last_byte = vector::borrow_mut(&mut student_addr_serialized, 31);
        *last_byte = 0;

        debug::print(&student_addr_serialized);

        //Verify commitment, indeed multiplied preimage of hash by some secret point to get aH_x, aH_y
        let is_valid_commitment = commit(proof_commit, student_a_hash, student_aH_x, student_aH_y, student_addr_serialized);
        assert!(is_valid_commitment, EStudentInvalidCommitment);

        //Verify that public professors kP_x, kP_y was indeed multiplied by some secret a, matching student's public commitment hash_a
        let is_valid_multiplication = unlock(proof_unlock, akP_x, akP_y, 
        student_addr_serialized, student_a_hash, *professor_kP_x, *professor_kP_y);
        assert!(is_valid_multiplication, EStudentBadMultiplication);

        //TODO: Add timestamp here later
        let timestamp_answered: vector<u8> = vector::empty();
        
        //Write this commitment to answer
        //Write this multiplication result to answer
        let answer = Answer {
            student_a_hash, 
            student_aH_x,   
            student_aH_y,   
            timestamp_answered, //Deal with it later
            student_address,
            akP_x,          
            akP_y,
        };

        if (has_place) table::add(answers, student_address, answer);
        event::emit(StudentAnsweredEvent{
            timestamp_answered, //Deal with it later
            student_address,
            akP_x,          
            akP_y,
            student_aH_x,
            student_aH_y,
        })
        //Add me to the answer Map
       

        //(Insight) when the price is not enough to reduce bots
        //Can be easily limited to one try per address
        //Or completely unique one-time questions can be made
        //Or different scheme with frozen collateral can be made
    }

    public entry fun professor_score_answer(shared_quest: &mut Quest, student: address, 
    proof:vector<u8>, professor_out_kaH_x: vector<u8>, professor_out_kaH_y: vector<u8>, ctx: &mut TxContext)
    {
        let _professor_address = tx_context::sender(ctx);
        let Quest {id: _, question: _, professor_address, professor_k_hash,
            professor_kP_x: _, professor_kP_y: _, } = shared_quest;
        let answers = ofield::borrow_mut<vector<u8>, Table<address, Answer>>(&mut shared_quest.id, b"answers");

        //Assert that this question belongs to this professor
        assert!(_professor_address == *professor_address, EAnotherProfessor);

        //professor_addr_serialized with first byte (least significant) flushed to make it fit 253-bit curve base field
        let professor_addr_serialized = address::to_bytes(_professor_address);
        let last_byte = vector::borrow_mut(&mut professor_addr_serialized, 31);
        *last_byte = 0;

        //Assert that this student answered indeed
        assert!(table::contains(answers, student), EStudentNoAnswer);

        //Extract his answer
        let student_answer = table::borrow(answers, student);

        let student_aH_x = student_answer.student_aH_x;
        let student_aH_y = student_answer.student_aH_y;
        
        //Do verified multiplication of student aH by k
        let multiplied = unlock(proof, professor_out_kaH_x, professor_out_kaH_y, 
        professor_addr_serialized, *professor_k_hash, student_aH_x, student_aH_y);

        //Assert it was verified groth16 proven
        assert!(multiplied, EProfessorBadMultiplication);

        //If verified professor_final point matches student_final_point
        let right_answer: bool = (professor_out_kaH_x == student_answer.akP_x) && (professor_out_kaH_y == student_answer.akP_y);
        if(right_answer){
            //Mint NFT to the student
            let nft = ProfessorNFT {
                id: object::new(ctx),
                name : string::utf8(b"Serenia"),
                description: string::utf8(b"From Soulmates collection. There is the whole world. Yet, just you two feel the life same. "),
                url: url::new_unsafe_from_bytes(b"https://ipfs.io/ipfs/bafybeifpvivgf4iuvwjv6r3z3ocuwrq3rpvb27xq32rnz6wepqgikd4x2m"),
            };
            transfer::transfer(nft, student_answer.student_address);
        } else{
            //Otherwise just do nothing (send the wrong answer NFT, any response is better than no)
            let nft = WrongAnswerNFT {
                id: object::new(ctx),
            };
            transfer::transfer(nft, student_answer.student_address);
        };
        
        //Pop the answer from answers table anyway
        table::remove(answers, student);       
    }

    public entry fun student_get_timeout_reward(_shared_quest: &Quest, _ctx: &TxContext)
    {
        //Lookup by caller address answer in shared_quest
        //Make sure there is one

        //Retrieve its timestamp: Do later when everything else is done
        //Use clock to get current: Do later when everything else is done
        //If professor (oracle) did not check the answer in 2 minutes

        //Pop answer 
        //Reward the caller with NFT

        //Do it last
        //But first just implement free mint here for any answer and Popping of answer
        //Improve it by allowing it only after timestamp + 2 minutes
    }

    fun verify(proof: vector<u8>, 
            vk_serialized: vector<u8>, public_inputs_serialized: vector<u8>): bool {
        let proof_serialized = hex::decode(proof);
        let curve: Curve = bn254();

        let pvk = prepare_verifying_key(&curve, &vk_serialized);
        // let pvk = pvk_from_bytes(vk_gamma_abc_g1_bytes,
        //     alpha_g1_beta_g2_bytes,
        //     gamma_g2_neg_pc_bytes,
        //     delta_g2_neg_pc_bytes);
        debug::print(&pvk);
        //debug::print(&pvk_bad);
        let public_inputs =  public_proof_inputs_from_bytes(public_inputs_serialized);
        let proof_points =  proof_points_from_bytes(proof_serialized);
        verify_groth16_proof(&curve, &pvk, &public_inputs, &proof_points)
    }

    fun commit(proof: vector<u8>, public_out_hash_a: vector<u8>, public_out_aP_x: vector<u8>, 
    public_out_aP_y: vector<u8>, public_in_address: vector<u8>): bool {
        //let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19f2120a4cbd4b722565aaec93c9396b90f08e18ef349d17266829ca76b93ec11698665b0b5fcf6c7aec74b944e9d26c390970feff9c35cdba1f615bb27e541a820500000000000000d05232298846333af5b9c786e300fb364e8f91277dfbd9113761976ef811bd8ae05f5921e1ea4e7a81d8e1217b553562139326591186de5ad755c02ca9519e2a2c8cd74dd2ca1759a54bcfd8d6bb03fcc2fc185ea98112e22fd667275112c7202c27f5c74e447fb310add441802dfa1d53bc87297703e7a90d0438166a2ab6a87b2099a5ca41e6c4c88a00eee53d4bd51c95d13cb8d03d19fa68352e59e9d997";
        let vk_serialized = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19f1555ee802f49f17c1ded7f8e0a35efd4a7caa5c66b14c5de3bc15e7ac579e02350ae505a137c6dd2a84365a88f2771ab96e4e33c0fdaf5b58ca9cf8528045870500000000000000d05232298846333af5b9c786e300fb364e8f91277dfbd9113761976ef811bd8ae05f5921e1ea4e7a81d8e1217b553562139326591186de5ad755c02ca9519e2a2c8cd74dd2ca1759a54bcfd8d6bb03fcc2fc185ea98112e22fd667275112c7202c27f5c74e447fb310add441802dfa1d53bc87297703e7a90d0438166a2ab6a87b2099a5ca41e6c4c88a00eee53d4bd51c95d13cb8d03d19fa68352e59e9d997";
        
        // let vk_gamma_abc_g1_bytes: vector<u8> = x"d05232298846333af5b9c786e300fb364e8f91277dfbd9113761976ef811bd8ae05f5921e1ea4e7a81d8e1217b553562139326591186de5ad755c02ca9519e2a2c8cd74dd2ca1759a54bcfd8d6bb03fcc2fc185ea98112e22fd667275112c7202c27f5c74e447fb310add441802dfa1d53bc87297703e7a90d0438166a2ab6a87b2099a5ca41e6c4c88a00eee53d4bd51c95d13cb8d03d19fa68352e59e9d997";
        // let alpha_g1_beta_g2_bytes: vector<u8> = x"0d14dc30b678357d988b3eb0e8ada11bc7b2b5d2cf0c1fe27522cb2a819b7c044a601bd9302a94a80677a9f72ebeaada131e9bfba30621c8f038b547beb9962e182089742c1d388436771390c6af9937729c39e6414746ee5636c4741d1f220df45c80a7cded5ad653bc4f8b201c94054918dee160e1dc90cea027d4ec69e01a6df0f8d739d7911aa63b6b6923f10cdce763de1046fe0f91d590f5f510397611c57ac6daac2f9222d8cc3130e57f99dcd2edecb3e1d11b860c0d9d64a5dda30f42b8a8e513c9d5983486332c3ecd1236192b988666c15818838559bc27b6a50f49fee88fd43ac88dc3e75419bfd451374e25b8c4845b4bfcbd460ad48bb55016e4e1edf293696a43b76c8a5feffe6cfddb59cd7bc0246c1784061ed3eff2280a74e56fcabc5b93d84d72e10a0ad78079b02d06cc8c3ae435936ce2e85722d82b9480a46f039988a80cf4ca669c026100f8ce3fbc5298180dec08d2055d7a621ad3cc4fdd99242a86d7c80528d3b438c4669288c56b77abb8367528a31f01c511";
        // let gamma_g2_neg_pc_bytes: vector<u8> = x"edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e99";
        // let delta_g2_neg_pc_bytes: vector<u8> = x"f1555ee802f49f17c1ded7f8e0a35efd4a7caa5c66b14c5de3bc15e7ac579e02350ae505a137c6dd2a84365a88f2771ab96e4e33c0fdaf5b58ca9cf852804507";

        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_hash_a));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_aP_y));
        append(&mut public_inputs_serialized, public_in_address);

        debug::print(&public_inputs_serialized);

        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        debug::print(&verification_result);
        verification_result
    }

    fun unlock(proof: vector<u8>, public_out_kaH_x: vector<u8>, public_out_kaH_y: vector<u8>, 
    public_in_address: vector<u8>, public_in_hash_k: vector<u8>, public_in_aH_x: vector<u8>, public_in_aH_y: vector<u8>, ): bool {
        //let vk_serialized: vector<u8> = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19887208fad3f8550e15bf3215798913226934b2d643d5a5f9c34a048aa168172467d50cca4f282065b87d49e7bc3e06b50b3675c66a1c2db2fedd8cbeed76ae2b0700000000000000d05232298846333af5b9c786e300fb364e8f91277dfbd9113761976ef811bd8a87f7c971b71d490782ad5a062ba629c632d23a8c32ccccbd6f90eef0706f4dae0de6bf1b29e90ec277a567aa9582c21e84322e41eb92789b0bec360a94061887494fd99769977a167bced33324f2e2fd654f141dc77844d8375e2d2d6bb55890c863813be5a227e8cc56108364ec7b07228479a299c26da09771ccb3b31a4a074616f0b4ea057686c6fd2d5bffbd4165a352e61744f2b27a971952ace6a9881061021a3b9efae96006b4e0334b7c0a437e941ebf91de9981acba5608b3825a08";
        let vk_serialized = x"e2f26dbea299f5223b646cb1fb33eadb059d9407559d7441dfd902e3a79a4d2dabb73dc17fbc13021e2471e0c08bd67d8401f52b73d6d07483794cad4778180e0c06f33bbc4c79a9cadef253a68084d382f17788f885c9afd176f7cb2f036789edf692d95cbdde46ddda5ef7d422436779445c5e66006a42761e1f12efde0018c212f3aeb785e49712e7a9353349aaf1255dfb31b7bf60723a480d9293938e19887208fad3f8550e15bf3215798913226934b2d643d5a5f9c34a048aa168172467d50cca4f282065b87d49e7bc3e06b50b3675c66a1c2db2fedd8cbeed76ae2b0700000000000000d05232298846333af5b9c786e300fb364e8f91277dfbd9113761976ef811bd8a87f7c971b71d490782ad5a062ba629c632d23a8c32ccccbd6f90eef0706f4dae0de6bf1b29e90ec277a567aa9582c21e84322e41eb92789b0bec360a94061887494fd99769977a167bced33324f2e2fd654f141dc77844d8375e2d2d6bb55890c863813be5a227e8cc56108364ec7b07228479a299c26da09771ccb3b31a4a074616f0b4ea057686c6fd2d5bffbd4165a352e61744f2b27a971952ace6a9881061021a3b9efae96006b4e0334b7c0a437e941ebf91de9981acba5608b3825a08";
        
        // let vk_gamma_abc_g1_bytes: vector<u8> = x"";
        // let alpha_g1_beta_g2_bytes: vector<u8> = x"";
        // let gamma_g2_neg_pc_bytes: vector<u8> = x"";
        // let delta_g2_neg_pc_bytes: vector<u8> = x"";

        let public_inputs_serialized: vector<u8> = x"";
        append(&mut public_inputs_serialized, hex::decode(public_out_kaH_x));
        append(&mut public_inputs_serialized, hex::decode(public_out_kaH_y));
        append(&mut public_inputs_serialized, public_in_address);
        append(&mut public_inputs_serialized, hex::decode(public_in_hash_k));
        append(&mut public_inputs_serialized, hex::decode(public_in_aH_x));
        append(&mut public_inputs_serialized, hex::decode(public_in_aH_y));
    
        let verification_result: bool = verify(proof, vk_serialized, public_inputs_serialized);
        verification_result
    }

    struct VERIFIER has drop {}
    fun init(otw: VERIFIER, ctx: &mut TxContext) {
       let keys = vector[
            string::utf8(b"name"),
            //utf8(b"link"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            //utf8(b"project_url"),
            //utf8(b"creator"),
        ];

        let values = vector[
            // For `name` we can use the `Hero.name` property
            string::utf8(b"{name}"),
            // For `link` we can build a URL using an `id` property
            //utf8(b"https://sui-heroes.io/hero/{id}"),
            // For `img_url` we use an IPFS template.
            string::utf8(b"{url}"),
            // Description is static for all `Hero` objects.
            string::utf8(b"{description}"),
            // Project URL is usually static
            //utf8(b"https://sui-heroes.io"),
            // Creator field can be any
            //utf8(b"Unknown Sui Fan")
        ];

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        // Get a new `Display` object for the `Hero` type.
        let display = display::new_with_fields<ProfessorNFT>(
            &publisher, keys, values, ctx
        );

        // Commit first version of `Display` to apply changes.
        display::update_version(&mut display);

        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }
}
// module dev::verifier_Tests {
//     use dev::verifier::{Self};
//     use sui::test_scenario as ts;
//     //use sui::transfer;
//     //use std::string;
//     //use std::debug;

//     #[test]
//     public fun test_verify(){
//         //let proof = b"a27c5205f9dfb4829a0c953d179dc171c23f5bb22ab4c866f0c090017e1ba60ab7a0f44108483acde4a05b294afafa2e2a751a0e4c6c8dc2e448161f5b35e02beaf88f2e9a8c9c5231a40083815dd30d4ad8db5a4552c3e40a67446625e1d008d4dc78a664286ca26be6ab055f1879b36f6d33f94d30581806439cf99ed9d593";
//         //let public_1 = b"8101000000000000000000000000000000000000000000000000000000000000";
//         //let public_2 = b"0500000000000000000000000000000000000000000000000000000000000000";
        
//         let professor_addr = @0x4f4b36185daad9eee80e0f1a3a9049e2439f482dd66075eb4c5563d6af6af984;
//         let scenario = ts::begin(professor_addr);

//         let question = b"What do you get when you add the right word to the end of this puzzle? : ";
//         //let proof = b"de608ec5ec2cb6a297ff5893def701def81d8f1f82da79bf3f684107f65254135155f4cdcf84aa9cb2bfa0bcf7bd539a232b717e5a0c051b714cb2a097978a0916594a5bee00dff8dbbdc0450f10e24794f904c31ffc41c4373653df2cd09386e205f6c420e9d5fc09f3f12c25b31f7dc171828897c8660e4c293c11e398cc0b";
//         let proof = b"14c658a46e8d17c57391db99d29282f339dbd0e3f6e637d08f4da468f6ca2721bdc1c182aa4145a94d3dadca1aa2f4757def818ef560d6fa2b503f36f2ef89194d87ef85a5200be2e81e75e86f91cdf3f61cb7ef62c92c7d1863d2951e8fb819b2317d21613dc15a435b5c0407bc7171da677b31d2c69e25af3a9c1b04f8d38f";
//         let professor_k_hash = b"44d4aeb951f3f58560834357aaa4b2c7b09b8c3a5892a5928f559aa419ee840b";
//         let professor_kP_x = b"c094563c2f31b3843d89c3a270a897cf1e623c7246e591bfec251112f48ed423";
//         let professor_kP_y = b"9e99e639652124a20f465f9edd62e1e50339a1eec8ad799def361f856974c806";


//         verifier::professor_create_quest(question, proof, professor_k_hash,
//         professor_kP_x, professor_kP_y, ts::ctx(&mut scenario));
//         //assert!(64==verify(), 1);
//         //let n = 64u64;
//         //debug::print(&n);
//         ts::end(scenario);
//     }
// }