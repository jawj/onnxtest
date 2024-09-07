use fastembed::{
    Pooling, QuantizationMode, TextEmbedding, TokenizerFiles, UserDefinedEmbeddingModel,
};

macro_rules! local_tokenizer_files {
    // NOTE: macro assumes /unix/style/paths
    ($folder:literal) => {
        TokenizerFiles {
            tokenizer_file: include_bytes!(concat!($folder, "/tokenizer.json")).to_vec(),
            config_file: include_bytes!(concat!($folder, "/config.json")).to_vec(),
            special_tokens_map_file: include_bytes!(concat!($folder, "/special_tokens_map.json"))
                .to_vec(),
            tokenizer_config_file: include_bytes!(concat!($folder, "/tokenizer_config.json"))
                .to_vec(),
        }
    };
}

macro_rules! local_model {
    // NOTE: macro assumes /unix/style/paths
    ($model:ident, $folder:literal) => {
        $model::new(
            include_bytes!(concat!($folder, "/model.onnx")).to_vec(),
            local_tokenizer_files!($folder),
        )
    };
}

fn main() {
    let model_files = local_model!(UserDefinedEmbeddingModel, "../bge_small_en_v15")
        .with_pooling(Pooling::Cls)
        .with_quantization(QuantizationMode::Static);

    let model = TextEmbedding::try_new_from_user_defined(model_files, Default::default())
        .expect("Couldn't load model bge_small_en_v15");

    let result = model
        .embed(vec!["The quick brown fox jumps over the lazy dog"], None)
        .expect("Unable to generate bge_small_en_v15 embeddings");

    println!("{:?}", result);
}
