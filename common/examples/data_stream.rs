use nm4p_common::data_stream::DataStreamWriter;
use serde::{Deserialize, Serialize};


fn main() {
    #[derive(Serialize, Deserialize)]
    struct Data {
        a: i32,
        b: i32,
    }

    // write
    {
        let n = 100000;
        let start = std::time::Instant::now();
        let mut w = DataStreamWriter::from_path("_tmp_data.yaml").unwrap();
        for i in 0..n {
            w.record(&Data { a: i, b: i + 1 });
        }
        w.finish();
        let elapsed = start.elapsed();
        println!("Wrote {n} records in {elapsed:?}");
    }

    // read
    {
        let start = std::time::Instant::now();
        let data: Vec<Data> = DataStreamWriter::deserialize_file("_tmp_data.yaml");
        let n = data.len();
        let elapsed = start.elapsed();
        println!("Read {n} records in {elapsed:?}");
    }
}