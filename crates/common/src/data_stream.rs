use std::{fs::File, io::{self, BufWriter, Read, Write}, path::Path};

use serde::{de::DeserializeOwned, Serialize};



/// A simple data stream writer that writes data in a YAML format.
///
/// # Example
///
/// Basic usage:
/// ```
/// # use nm4p_common::data_stream::DataStreamWriter;
/// let mut s = DataStreamWriter::new_on_string();
/// s.record(&1);
/// s.record(&2);
/// s.record(&3);
/// let data_yaml = s.finish_string();
/// assert_eq!(data_yaml, "- 1\n- 2\n- 3\n");
/// ```
///
/// Writing to a file:
/// ```
/// # use nm4p_common::data_stream::DataStreamWriter;
/// let mut s = DataStreamWriter::from_path("_tmp_data.yaml").unwrap();
/// s.record(&1);
/// s.record(&2);
/// s.record(&3);
/// s.flush();
/// ```
pub struct DataStreamWriter<W, T> {
    writer: W,
    _phantom: std::marker::PhantomData<T>,
}

impl DataStreamWriter<(), ()> {
    pub fn deserialize<R: Read, T: DeserializeOwned>(reader: R) -> Vec<T> {
        serde_yaml::from_reader(reader).unwrap()
    }

    pub fn deserialize_str<T: DeserializeOwned>(s: &str) -> Vec<T> {
        Self::deserialize(s.as_bytes())
    }

    pub fn deserialize_file<T: DeserializeOwned, P: AsRef<Path>>(path: P) -> Vec<T> {
        let content = std::fs::read_to_string(path).unwrap();
        let parts = content.split("\n---\n").collect::<Vec<_>>();
        Self::deserialize_str(parts.last().cloned().unwrap_or(""))
    }
}

impl<W: Write, T: Serialize> DataStreamWriter<W, T> {
    pub fn new(writer: W) -> Self {
        Self {
            writer,
            _phantom: std::marker::PhantomData,
        }
    }

    pub fn with_header_data(
        mut self,
        comment: &str,
        data: impl Serialize,
    ) -> Self {
        let header = {
            let comment = comment.lines().map(|line| format!("# {}\n", line)).collect::<String>();
            let data = serde_yaml::to_string(&data).unwrap();
            format!("{}\n{}\n---\n", comment, data)
        };
        self.writer.write_all(header.as_bytes()).unwrap();
        self
    }

    /// Write data to the writer.
    pub fn record(&mut self, data: &T) {
        struct YamlJsonCompactSerializer;
        impl serde_json::ser::Formatter for YamlJsonCompactSerializer {
            fn begin_object_value<W>(&mut self, writer: &mut W) -> std::io::Result<()>
            where
                W: ?Sized + std::io::Write
            {
                writer.write_all(b": ")
            }
            fn begin_string<W>(&mut self, _writer: &mut W) -> io::Result<()>
            where
                W: ?Sized + io::Write, {
                Ok(())
            }
            fn write_string_fragment<W>(&mut self, writer: &mut W, fragment: &str) -> io::Result<()>
            where
                W: ?Sized + io::Write, {
                if fragment.contains('\\') || fragment.contains(' ') {
                    writer.write_all(b"\"")?;
                    writer.write_all(fragment.as_bytes())?;
                    writer.write_all(b"\"")
                } else {
                    writer.write_all(fragment.as_bytes())
                }
            }
            fn end_string<W>(&mut self, _writer: &mut W) -> io::Result<()>
                where
                    W: ?Sized + io::Write, {
                Ok(())
            }
        }
        self.writer.write_all(b"- ").unwrap();
        {
            let mut ser = serde_json::Serializer::with_formatter(&mut self.writer, YamlJsonCompactSerializer);
            data.serialize(&mut ser).expect("Failed to serialize data");
        }
        self.writer.write_all(b"\n").unwrap();
    }

    /// Flush the writer.
    ///
    /// This is useful when the writer is buffered, for example when writing to a file
    /// using a [`BufWriter`].
    pub fn flush(&mut self) {
        self.writer.flush().expect("Failed to flush writer");
    }

    /// Finish writing and return the writer.
    pub fn finish(mut self) -> W {
        self.flush();
        self.writer
    }
}

impl<T: Serialize> DataStreamWriter<BufWriter<File>, T> {
    /// Create a new [`DataStreamWriter`] that writes to a file using a buffered writer.
    pub fn new_on_file_buffered(file: File) -> Self {
        let writer = BufWriter::new(file);
        Self::new(writer)
    }

    /// Create a new [`DataStreamWriter`] that writes to a file using a buffered writer.
    pub fn from_path<P: AsRef<Path>>(path: P) -> std::io::Result<Self> {
        let file = std::fs::File::create(path)?;
        let writer = BufWriter::new(file);
        Ok(Self::new(writer))
    }
}

impl<T: Serialize> DataStreamWriter<Vec<u8>, T> {
    /// Create a new `DataStreamWriter` that writes to a string.
    ///
    /// Writing data on a string defeats the purpose of using a `DataStreamWriter` but it can be useful for testing.
    pub fn new_on_string() -> Self {
        Self::new(Vec::new())
    }

    /// Finish writing and return the data as a string.
    pub fn finish_string(self) -> String {
        String::from_utf8(self.finish()).expect("Failed to convert to string")
    }
}