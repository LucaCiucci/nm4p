fn main() {
    println!("Hello, world!");

    let file = "mod_1/xtask.yaml";
    let file = std::path::Path::new(file);
    let yaml = std::fs::read_to_string(file).unwrap();
    let yaml = yaml_rust::YamlLoader::load_from_str(&yaml).unwrap();
    let doc = &yaml[0];

    let tasks = doc
        .as_hash()
        .unwrap()
        .iter()
        .map(|a| a.0.as_str().unwrap())
        .collect::<Vec<_>>();

    for task_name in tasks {
        println!("running xtask: {}", task_name);
        let command_and_args = if let Some(s) = doc[task_name].as_str() {
            s.split(" ").map(|s| s.to_string()).collect::<Vec<_>>()
        } else if let Some(v) = doc[task_name].as_vec() {
            v.iter()
                .map(|a| {
                    let s = if let Some(s) = a.as_str() {
                        s.split(" ").map(|s| s.to_string()).collect::<Vec<_>>()
                    } else if let Some(n) = a.as_i64() {
                        vec![n.to_string().to_string()]
                    } else {
                        panic!("invalid xtask.yaml");
                    };
                    s
                })
                .flatten()
                .collect::<Vec<_>>()
        } else {
            panic!("invalid xtask.yaml");
        };
        let command = &command_and_args[0];
        let args = &command_and_args[1..];
        println!("command: {}", command);
        println!("args: {:?}", args);
        let out = std::process::Command::new(command)
            .args(args)
            .stdout(std::process::Stdio::inherit())
            .stderr(std::process::Stdio::inherit())
            .stdin(std::process::Stdio::inherit())
            .output()
            .expect("failed to execute process");
        let out = String::from_utf8(out.stdout).unwrap();
        println!("{}", out);
    }

    //let cwd_out = std::process::Command::new("cargo")
    //    .args("run --example metropolis-gauss -- 1000 --seed 42 --mu 10 --sigma 1 --x0 0 --delta 1 --plot mod_1/img/primo_test_metrogauss".split(" "))
    //    .output()
    //    .expect("failed to execute process");
    //let cwd = String::from_utf8(cwd_out.stdout).unwrap();
    //println!("cwd: {}", cwd);
}
