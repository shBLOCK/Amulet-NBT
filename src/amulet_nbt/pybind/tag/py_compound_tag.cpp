#include <memory>
#include <unordered_map>
#include <string>
#include <bit>
#include <variant>
#include <utility>
#include <vector>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/operators.h>

#include <amulet_nbt/common.hpp>
#include <amulet_nbt/tag/wrapper.hpp>
#include <amulet_nbt/tag/compound.hpp>
#include <amulet_nbt/tag/eq.hpp>
#include <amulet_nbt/tag/copy.hpp>

namespace py = pybind11;


void CompoundTag_update(Amulet::CompoundTag& self, py::dict other){
    auto map = other.cast<std::unordered_map<std::string, Amulet::WrapperNode>>();
    for (auto it = map.begin(); it != map.end(); it++){
        if (it->second.index() == 0){
            throw py::type_error("Value cannot be None");
        }
        self[it->first] = unwrap_node(it->second);
    }
}


void init_compound(py::module& m) {
    py::class_<Amulet::CompoundTagIterator> CompoundTagIterator(m, "CompoundTagIterator");
        CompoundTagIterator.def(
            "__next__",
            [](Amulet::CompoundTagIterator& self) -> py::object {
                if (self.has_next()){
                    std::string key = self.next();
                    try {
                        return py::str(key);
                    } catch (py::error_already_set&){
                        return py::bytes(key);
                    }
                }
                throw py::stop_iteration("");
            }
        );
        CompoundTagIterator.def(
            "__iter__",
            [](Amulet::CompoundTagIterator& self){
                return self;
            }
        );

    py::object AbstractBaseTag = m.attr("AbstractBaseTag");
    py::object isinstance = py::module::import("builtins").attr("isinstance");

    py::class_<Amulet::CompoundTagWrapper, Amulet::AbstractBaseMutableTag> CompoundTag(m, "CompoundTag",
        "A Python wrapper around a C++ unordered map.\n"
        "\n"
        "Note that this class is not thread safe and inherits all the limitations of a C++ unordered_map."
    );
        CompoundTag.def_property_readonly_static("tag_id", [](py::object) {return 10;});
        CompoundTag.def(
            py::init([](py::object value, const py::kwargs& kwargs) {
                Amulet::CompoundTagPtr tag = std::make_shared<Amulet::CompoundTag>();
                CompoundTag_update(*tag, py::dict(value));
                CompoundTag_update(*tag, kwargs);
                return Amulet::CompoundTagWrapper(tag);
            }),
            py::arg("value") = py::tuple()
        );
        auto py_getter = [](const Amulet::CompoundTagWrapper& self){
            py::dict out;
            for (auto it = self.tag->begin(); it != self.tag->end(); it++){
                py::object value = py::cast(Amulet::wrap_node(it->second));
                try {
                    py::str key = py::str(it->first);
                    out[key] = value;
                } catch (py::error_already_set&){
                    py::bytes key = py::bytes(it->first);
                    out[key] = value;
                }
            }
            return out;
        };
        CompoundTag.def_property_readonly(
            "py_dict",
            py_getter,
            py::doc("A shallow copy of the CompoundTag as a python dictionary.")
        );
        CompoundTag.def_property_readonly(
            "py_data",
            py_getter,
            py::doc(
                "A python representation of the class. Note that the return type is undefined and may change in the future.\n"
                "\n"
                "You would be better off using the py_{type} or np_array properties if you require a fixed type.\n"
                "This is here for convenience to get a python representation under the same property name.\n"
            )
        );
        CompoundTag.def(
            "__repr__",
            [](const Amulet::CompoundTagWrapper& self){
                std::string out;
                out += "CompoundTag({";
                for (auto it = self.tag->begin(); it != self.tag->end(); it++){
                    if (it != self.tag->begin()){out += ", ";}
                    try {
                        out += py::repr(py::str(it->first));
                    } catch (py::error_already_set&){
                        out += py::repr(py::bytes(it->first));
                    }
                    out += ": ";
                    out += py::repr(py::cast(Amulet::wrap_node(it->second)));
                }
                out += "})";
                return out;
            }
        );
        CompoundTag.def(
            py::pickle(
                [](const Amulet::CompoundTagWrapper& self){
                    return py::bytes(Amulet::write_nbt("", self.tag, std::endian::big, Amulet::utf8_to_mutf8));
                },
                [](py::bytes state){
                    return Amulet::CompoundTagWrapper(
                        std::get<Amulet::CompoundTagPtr>(
                            Amulet::read_nbt(state, std::endian::big, Amulet::mutf8_to_utf8).tag_node
                        )
                    );
                }
            )
        );
        CompoundTag.def(
            "__copy__",
            [](const Amulet::CompoundTagWrapper& self){
                return Amulet::CompoundTagWrapper(NBTTag_copy<Amulet::CompoundTag>(*self.tag));
            }
        );
        CompoundTag.def(
            "__deepcopy__",
            [](const Amulet::CompoundTagWrapper& self, py::dict){
                return Amulet::CompoundTagWrapper(Amulet::NBTTag_deep_copy_compound(*self.tag));
            },
            py::arg("memo")
        );
        CompoundTag.def(
            "__str__",
            [](const Amulet::CompoundTagWrapper& self){
                return py::str(py::dict(py::cast(self)));
            }
        );
        CompoundTag.def(
            "__eq__",
            [](const Amulet::CompoundTagWrapper& self, const Amulet::CompoundTagWrapper& other){
                return Amulet::NBTTag_eq(self.tag, other.tag);
            },
            py::is_operator()
        );
        CompoundTag.def(
            "__len__",
            [](const Amulet::CompoundTagWrapper& self){
                return self.tag->size();
            }
        );
        CompoundTag.def(
            "__bool__",
            [](const Amulet::CompoundTagWrapper& self){
                return !self.tag->empty();
            }
        );
        CompoundTag.def(
            "__iter__",
            [](const Amulet::CompoundTagWrapper& self){
                return Amulet::CompoundTagIterator(self.tag);
            }
        );
        CompoundTag.def(
            "__getitem__",
            [](const Amulet::CompoundTagWrapper& self, std::string key){
                auto it = self.tag->find(key);
                if (it == self.tag->end()){
                    throw py::key_error(key);
                }
                return Amulet::wrap_node(it->second);
            }
        );
        CompoundTag.def(
            "get",
            [isinstance](const Amulet::CompoundTagWrapper& self, std::string key, py::object default_, py::object cls) -> py::object {
                auto it = self.tag->find(key);
                if (it == self.tag->end()){
                    return default_;
                }
                py::object tag = py::cast(Amulet::wrap_node(it->second));
                if (isinstance(tag, cls)){
                    return tag;
                } else {
                    return default_;
                }
            },
            py::arg("key"), py::arg("default") = py::none(), py::arg("cls") = AbstractBaseTag,
            py::doc(
                "Get an item from the CompoundTag.\n"
                "\n"
                ":param key: The key to get\n"
                ":param default: The value to return if the key does not exist or the type is wrong.\n"
                ":param cls: The class that the stored tag must inherit from. If the type is incorrect default is returned.\n"
                ":return: The tag stored in the CompoundTag if the type is correct else default.\n"
                ":raises: KeyError if the key does not exist.\n"
                ":raises: TypeError if the stored type is not a subclass of cls."
            )
        );
        CompoundTag.def(
            "__contains__",
            [](const Amulet::CompoundTagWrapper& self, std::string key){
                auto it = self.tag->find(key);
                return it != self.tag->end();
            }
        );
        py::object KeysView = py::module::import("collections.abc").attr("KeysView");
        CompoundTag.def(
            "keys",
            [KeysView](const Amulet::CompoundTagWrapper& self){
                return KeysView(py::cast(self));
            }
        );
        py::object ItemsView = py::module::import("collections.abc").attr("ItemsView");
        CompoundTag.def(
            "items",
            [ItemsView](const Amulet::CompoundTagWrapper& self){
                return ItemsView(py::cast(self));
            }
        );
        py::object ValuesView = py::module::import("collections.abc").attr("ValuesView");
        CompoundTag.def(
            "values",
            [ValuesView](const Amulet::CompoundTagWrapper& self){
                return ValuesView(py::cast(self));
            }
        );
        CompoundTag.def(
            "__setitem__",
            [](const Amulet::CompoundTagWrapper& self, std::string key, Amulet::WrapperNode value){
                if (value.index() == 0){
                    throw py::type_error("Value cannot be None");
                }
                (*self.tag)[key] = Amulet::unwrap_node(value);
            }
        );
        CompoundTag.def(
            "__delitem__",
            [](const Amulet::CompoundTagWrapper& self, std::string key){
                auto it = self.tag->find(key);
                if (it == self.tag->end()){
                    throw py::key_error(key);
                }
                self.tag->erase(it);
            }
        );
        py::object marker = py::module::import("builtins").attr("object")();
        CompoundTag.def(
            "pop",
            [marker](const Amulet::CompoundTagWrapper& self, std::string key, py::object default_) -> py::object {
                auto it = self.tag->find(key);
                if (it == self.tag->end()){
                    if (default_.is(marker)){
                        throw py::key_error(key);
                    } else {
                        return default_;
                    }
                }
                Amulet::WrapperNode tag = Amulet::wrap_node(it->second);
                self.tag->erase(it);
                return py::cast(tag);
            },
            py::arg("key"), py::arg("default") = marker
        );
        CompoundTag.def(
            "popitem",
            [](const Amulet::CompoundTagWrapper& self) -> std::pair<std::variant<py::str, py::bytes>, Amulet::WrapperNode>{
                auto it = self.tag->begin();
                if (it == self.tag->end()){
                    throw py::key_error("CompoundTag is empty.");
                }
                std::string key = it->first;
                Amulet::WrapperNode value = Amulet::wrap_node(it->second);
                self.tag->erase(it);
                try {
                    py::str py_key = py::str(key);
                    return std::make_pair(py_key, value);
                } catch (py::error_already_set&){
                    py::bytes py_key = py::bytes(key);
                    return std::make_pair(py_key, value);
                }
            }
        );
        CompoundTag.def(
            "clear",
            [](const Amulet::CompoundTagWrapper& self){
                self.tag->clear();
            }
        );
        CompoundTag.def(
            "update",
            [](const Amulet::CompoundTagWrapper& self, py::object other, const py::kwargs& kwargs){
                CompoundTag_update(*self.tag, py::dict(other));
                CompoundTag_update(*self.tag, kwargs);
            },
            py::arg("other") = py::tuple(), py::pos_only()
        );
        CompoundTag.def(
            "setdefault",
            [isinstance](const Amulet::CompoundTagWrapper& self, std::string key, Amulet::WrapperNode tag, py::object cls) -> py::object {
                auto set_value = [self, key, tag](){
                    if (tag.index() == 0){
                        throw py::type_error("Cannot setdefault a value of None.");
                    }
                    (*self.tag)[key] = Amulet::unwrap_node(tag);
                    return py::cast(tag);
                };
                auto it = self.tag->find(key);
                if (it == self.tag->end()){
                    return set_value();
                }
                py::object existing_tag = py::cast(Amulet::wrap_node(it->second));
                if (!isinstance(existing_tag, cls)){
                    // if the key exists but has the wrong type then set it
                    return set_value();
                }
                return existing_tag;
            },
            py::arg("key"), py::arg("tag") = py::none(), py::arg("cls") = AbstractBaseTag
        );
        CompoundTag.def_static(
            "fromkeys",
            [](py::object keys, Amulet::WrapperNode value){
                if (value.index() == 0){
                    throw py::type_error("Value cannot be None");
                }
                Amulet::TagNode node = Amulet::unwrap_node(value);
                Amulet::CompoundTagPtr tag = std::make_shared<Amulet::CompoundTag>();
                for (std::string& key: keys.cast<std::vector<std::string>>()){
                    (*tag)[key] = node;
                }
                return Amulet::CompoundTagWrapper(tag);
            }
        );

        #define CASE(ID, TAG_NAME, TAG, TAG_STORAGE, LIST_TAG)\
        CompoundTag.def(\
            "get_"TAG_NAME,\
            [](\
                const Amulet::CompoundTagWrapper& self,\
                std::string key,\
                std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> default_,\
                bool raise_errors\
            ) -> std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> {\
                auto it = self.tag->find(key);\
                if (it == self.tag->end()){\
                    if (raise_errors){\
                        throw pybind11::key_error(key);\
                    } else {\
                        return default_;\
                    }\
                }\
                py::object tag = py::cast(Amulet::wrap_node(it->second));\
                if (py::isinstance<Amulet::TagWrapper<TAG_STORAGE>>(tag)){\
                    return tag.cast<Amulet::TagWrapper<TAG_STORAGE>>();\
                } else if (raise_errors){\
                    throw pybind11::type_error(key);\
                } else {\
                    return default_;\
                }\
            },\
            py::arg("key"), py::arg("default") = py::none(), py::arg("raise_errors") = false,\
            py::doc(\
                "Get the tag stored in key if it is a "#TAG".\n"\
                "\n"\
                ":param key: The key to get\n"\
                ":param default: The value to return if the key does not exist or the type is wrong.\n"\
                ":param raise_errors: If True, KeyError and TypeError are raise on error. If False, default is returned on error.\n"\
                ":return: The "#TAG".\n"\
                ":raises: KeyError if the key does not exist and raise_errors is True.\n"\
                ":raises: TypeError if the stored type is not a "#TAG" and raise_errors is True."\
            )\
        );\
        CompoundTag.def(\
            "setdefault_"TAG_NAME,\
            [isinstance](\
                const Amulet::CompoundTagWrapper& self,\
                std::string key,\
                std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> default_\
            ) -> std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> {\
                auto set_and_return = [self, key](TAG_STORAGE tag){\
                    Amulet::TagNode node(tag);\
                    (*self.tag)[key] = node;\
                    return Amulet::TagWrapper<TAG_STORAGE>(tag);\
                };\
                auto create_set_return = [set_and_return, default_](){\
                    if (default_.index() == 0){\
                        if constexpr (is_shared_ptr<TAG_STORAGE>::value){\
                            return set_and_return(std::make_shared<TAG_STORAGE::element_type>());\
                        } else {\
                            return set_and_return(TAG_STORAGE());\
                        }\
                    } else {\
                        return set_and_return(std::get<Amulet::TagWrapper<TAG_STORAGE>>(default_).tag);\
                    }\
                };\
                auto it = self.tag->find(key);\
                if (it == self.tag->end()){\
                    return create_set_return();\
                }\
                py::object existing_tag = py::cast(Amulet::wrap_node(it->second));\
                if (py::isinstance<Amulet::TagWrapper<TAG_STORAGE>>(existing_tag)){\
                    return existing_tag.cast<Amulet::TagWrapper<TAG_STORAGE>>();\
                } else {\
                    /* if the key exists but has the wrong type then set it */\
                    return create_set_return();\
                }\
            },\
            py::arg("key"), py::arg("default") = py::none(),\
            py::doc(\
                "Populate key if not defined or value is not "#TAG". Return the value stored\n."\
                "\n"\
                "If default is a "#TAG" then it will be stored under key else a default instance will be created.\n"\
                "\n"\
                ":param key: The key to populate and get\n"\
                ":param default: The default value to use. If None, the default "#TAG" is used.\n"\
                ":return: The "#TAG" stored in key"\
            )\
        );\
        CompoundTag.def(\
            "pop_"TAG_NAME,\
            [marker](\
                const Amulet::CompoundTagWrapper& self,\
                std::string key,\
                std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> default_,\
                bool raise_errors\
            ) -> std::variant<std::monostate, Amulet::TagWrapper<TAG_STORAGE>> {\
                auto it = self.tag->find(key);\
                if (it == self.tag->end()){\
                    if (raise_errors){\
                        throw py::key_error(key);\
                    } else {\
                        return default_;\
                    }\
                }\
                py::object existing_tag = py::cast(Amulet::wrap_node(it->second));\
                if (py::isinstance<Amulet::TagWrapper<TAG_STORAGE>>(existing_tag)){\
                    self.tag->erase(it);\
                    return existing_tag.cast<Amulet::TagWrapper<TAG_STORAGE>>();\
                } else if (raise_errors){\
                    throw pybind11::type_error(key);\
                } else {\
                    return default_;\
                }\
            },\
            py::arg("key"), py::arg("default") = py::none(), py::arg("raise_errors") = false,\
            py::doc(\
                "Remove the specified key and return the corresponding value if it is a "#TAG".\n"\
                "\n"\
                "If the key exists but the type is incorrect, the value will not be removed.\n"\
                "\n"\
                ":param key: The key to get and remove\n"\
                ":param default: The value to return if the key does not exist or the type is wrong.\n"\
                ":param raise_errors: If True, KeyError and TypeError are raise on error. If False, default is returned on error.\n"\
                ":return: The "#TAG".\n"\
                ":raises: KeyError if the key does not exist and raise_errors is True.\n"\
                ":raises: TypeError if the stored type is not a "#TAG" and raise_errors is True."\
            )\
        );\

        FOR_EACH_LIST_TAG(CASE)
        #undef CASE
}
