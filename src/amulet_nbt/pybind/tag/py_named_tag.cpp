#include <fstream>
#include <stdexcept>
#include <string>
#include <memory>
#include <bit>
#include <ios>
#include <variant>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>

#include <amulet_nbt/tag/nbt.hpp>
#include <amulet_nbt/tag/wrapper.hpp>
#include <amulet_nbt/tag/eq.hpp>
#include <amulet_nbt/tag/copy.hpp>
#include <amulet_nbt/nbt_encoding/binary.hpp>
#include <amulet_nbt/nbt_encoding/string.hpp>
#include <amulet_nbt/pybind/encoding.hpp>

namespace py = pybind11;


namespace AmuletPy {
    class NamedTagIterator {
        private:
            py::object named_tag;
            size_t index;
        public:
            NamedTagIterator(py::object named_tag): named_tag(named_tag), index(0){}
            py::object next(){
                switch(index){
                    case 0:
                        index++;
                        return named_tag.attr("name");
                    case 1:
                        index++;
                        return named_tag.attr("tag");
                    default:
                        throw pybind11::stop_iteration("");
                }
            }
    };
}


void init_named_tag(py::module& m) {
    py::object mutf8_encoding = m.attr("mutf8_encoding");
    py::object java_encoding = m.attr("java_encoding");
    py::object compress = py::module::import("gzip").attr("compress");

    py::class_<AmuletPy::NamedTagIterator> NamedTagIterator(m, "NamedTagIterator");
        NamedTagIterator.def(
            "__next__",
            &AmuletPy::NamedTagIterator::next
        );
        NamedTagIterator.def(
            "__iter__",
            [](AmuletPy::NamedTagIterator& self){
                return self;
            }
        );

    py::class_<Amulet::NamedTag> NamedTag(m, "NamedTag");
        NamedTag.def(
            py::init([](Amulet::WrapperNode tag, std::string name) {
                if (tag.index() == 0){
                    return Amulet::NamedTag(name, std::make_shared<Amulet::CompoundTag>());
                } else {
                    return Amulet::NamedTag(name, Amulet::unwrap_node(tag));
                }
            }),
            py::arg("tag") = py::none(), py::arg("name") = ""
        );
        NamedTag.def_property(
            "name",
            [](const Amulet::NamedTag& self) -> py::object {
                try {
                    return py::str(self.name);
                } catch (py::error_already_set&){
                    return py::bytes(self.name);
                }
            },
            [](Amulet::NamedTag& self, std::string name){
                self.name = name;
            }
        );
        NamedTag.def_property(
            "tag",
            [](const Amulet::NamedTag& self){
                return Amulet::wrap_node(self.tag_node);
            },
            [](Amulet::NamedTag& self, Amulet::WrapperNode tag){
                if (tag.index() == 0){
                    throw std::invalid_argument("tag cannot be None");
                }
                self.tag_node = Amulet::unwrap_node(tag);
            }
        );
        auto to_nbt = [compress](
            const Amulet::NamedTag& self,
            bool compressed,
            std::endian endianness,
            Amulet::StringEncode string_encoder
        ) -> py::bytes {
            py::bytes data = Amulet::write_nbt(self.name, self.tag_node, endianness, string_encoder);
            if (compressed){
                return compress(data);
            }
            return data;
        };
        NamedTag.def(
            "to_nbt",
            [to_nbt](
                const Amulet::NamedTag& self,
                Amulet::EncodingPreset preset
            ){
                return to_nbt(
                    self,
                    preset.compressed,
                    preset.endianness,
                    preset.string_encoding.encode
                );
            },
            py::kw_only(),
            py::arg("preset") = java_encoding
        );
        NamedTag.def(
            "to_nbt",
            [to_nbt](
                const Amulet::NamedTag& self,
                bool compressed,
                bool little_endian,
                Amulet::StringEncoding string_encoding
            ){
                return to_nbt(
                    self,
                    compressed,
                    little_endian ? std::endian::little : std::endian::big,
                    string_encoding.encode
                );
            },
            py::kw_only(),
            py::arg("compressed") = true,
            py::arg("little_endian") = false,
            py::arg("string_encoding") = mutf8_encoding
        );
        auto save_to = [to_nbt](
            const Amulet::NamedTag& self,
            py::object filepath_or_writable,
            bool compressed,
            std::endian endianness,
            Amulet::StringEncode string_encoder
        ){
            py::bytes py_data = to_nbt(self, compressed, endianness, string_encoder);
            if (!filepath_or_writable.is(py::none())){
                if (py::isinstance<py::str>(filepath_or_writable)){
                    std::string data = py_data.cast<std::string>();
                    std::ofstream file(filepath_or_writable.cast<std::string>(), std::ios::out | std::ios::binary | std::ios::trunc);
                    file.write(data.c_str(), data.size());
                } else {
                    filepath_or_writable.attr("write")(py_data);
                }
            }
            return py_data;
        };
        NamedTag.def(
            "save_to",
            [save_to](
                const Amulet::NamedTag& self,
                py::object filepath_or_writable,
                Amulet::EncodingPreset preset
            ){
                return save_to(
                    self,
                    filepath_or_writable,
                    preset.compressed,
                    preset.endianness,
                    preset.string_encoding.encode
                );
            },
            py::arg("filepath_or_writable") = py::none(),
            py::pos_only(),
            py::kw_only(),
            py::arg("preset") = java_encoding
        );
        NamedTag.def(
            "save_to",
            [save_to](
                const Amulet::NamedTag& self,
                py::object filepath_or_writable,
                bool compressed,
                bool little_endian,
                Amulet::StringEncoding string_encoding
            ){
                return save_to(
                    self,
                    filepath_or_writable,
                    compressed,
                    little_endian ? std::endian::little : std::endian::big,
                    string_encoding.encode
                );
            },
            py::arg("filepath_or_writable") = py::none(),
            py::pos_only(),
            py::kw_only(),
            py::arg("compressed") = true,
            py::arg("little_endian") = false,
            py::arg("string_encoding") = mutf8_encoding
        );
        NamedTag.def(
            "to_snbt",
            [](
                const Amulet::NamedTag& self,
                py::object indent
            ){
                if (indent.is(py::none())){
                    return Amulet::write_snbt(self.tag_node);
                } else if (py::isinstance<py::int_>(indent)){
                    return Amulet::write_formatted_snbt(self.tag_node, std::string(indent.cast<size_t>(), ' '));
                } else if (py::isinstance<py::str>(indent)){
                    return Amulet::write_formatted_snbt(self.tag_node, indent.cast<std::string>());
                } else {
                    throw std::invalid_argument("indent must be None, int or str");
                }
            },
            py::arg("indent") = py::none()
        );
        NamedTag.def(
            "__repr__",
            [](const Amulet::NamedTag& self){
                std::string out;
                out += "NamedTag(";
                out += py::repr(py::cast(Amulet::wrap_node(self.tag_node)));
                out += ", ";
                try {
                    out += py::repr(py::str(self.name));
                } catch (py::error_already_set&){
                    out += py::repr(py::bytes(self.name));
                }
                out += ")";
                return out;
            }
        );
        NamedTag.def(
            py::pickle(
                [](const Amulet::NamedTag& self){
                    return py::bytes(Amulet::write_nbt(self, std::endian::big, Amulet::utf8_to_mutf8));
                },
                [](py::bytes state){
                    return Amulet::read_nbt(state, std::endian::big, Amulet::mutf8_to_utf8);
                }
            )
        );
        NamedTag.def(
            "__copy__",
            [](const Amulet::NamedTag& self){
                return self;
            }
        );
        NamedTag.def(
            "__deepcopy__",
            [](const Amulet::NamedTag& self, py::dict){
                return Amulet::NamedTag(self.name, Amulet::NBTTag_deep_copy_node(self.tag_node));
            },
            py::arg("memo")
        );
        NamedTag.def(
            "__eq__",
            [](const Amulet::NamedTag& self, const Amulet::NamedTag& other){
                return self.name == other.name && Amulet::NBTTag_eq(self.tag_node, other.tag_node);
            },
            py::is_operator()
        );
        NamedTag.def(
            "__getitem__",
            [](const Amulet::NamedTag& self, Py_ssize_t item) -> py::object {
                if (item < 0){
                    item += 2;
                }
                switch (item){
                    case 0:
                        return py::cast(self).attr("name");
                    case 1:
                        return py::cast(self).attr("tag");
                    default:
                        throw std::out_of_range("Index out of range");
                }
            }
        );
        NamedTag.def(
            "__iter__",
            [](const Amulet::NamedTag& self){
                return AmuletPy::NamedTagIterator(py::cast(self));
            }
        );

        #define CASE(ID, TAG_NAME, TAG, TAG_STORAGE, LIST_TAG)\
        NamedTag.def_property_readonly(\
            TAG_NAME,\
            [](const Amulet::NamedTag& self){\
                if (self.tag_node.index() != ID){\
                    throw pybind11::type_error("tag_node is not a "#TAG);\
                }\
                return Amulet::TagWrapper<TAG_STORAGE>(std::get<TAG_STORAGE>(self.tag_node));\
            },\
            py::doc(\
                "Get the tag if it is a "#TAG".\n"\
                "\n"\
                ":return: The "#TAG".\n"\
                ":raises: TypeError if the stored type is not a "#TAG\
            )\
        );\

        FOR_EACH_LIST_TAG(CASE)
        #undef CASE
}
