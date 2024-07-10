#pragma once

#include <string>
#include <bit>

#include <amulet_nbt/common.hpp>
#include <amulet_nbt/tag/nbt.hpp>
#include <amulet_nbt/nbt_encoding/binary.hpp>
#include <amulet_nbt/nbt_encoding/string.hpp>
#include <amulet_nbt/io/binary_writer.hpp>

namespace Amulet {

    class AbstractBaseTag {
        public:
            virtual std::string to_nbt(std::string, std::endian, Amulet::StringEncode) const = 0;
            virtual std::string to_snbt() const = 0;
            virtual std::string to_snbt(const std::string& indent) const = 0;
    };

    class AbstractBaseImmutableTag: public AbstractBaseTag {};
    class AbstractBaseMutableTag: public AbstractBaseTag {};
    class AbstractBaseNumericTag: public AbstractBaseImmutableTag {};
    class AbstractBaseIntTag: public AbstractBaseNumericTag {};
    class AbstractBaseFloatTag: public AbstractBaseNumericTag {};
    class AbstractBaseArrayTag: public AbstractBaseMutableTag {};

    // pybind cannot directly store fundamental types
    // This wrapper exists to allow pybind to store fundamental types
    template <typename T>
    class TagWrapper: public
        std::conditional_t<std::is_same_v<T, ByteTag>, AbstractBaseIntTag,
        std::conditional_t<std::is_same_v<T, ShortTag>, AbstractBaseIntTag,
        std::conditional_t<std::is_same_v<T, IntTag>, AbstractBaseIntTag,
        std::conditional_t<std::is_same_v<T, LongTag>, AbstractBaseIntTag,
        std::conditional_t<std::is_same_v<T, FloatTag>, AbstractBaseFloatTag,
        std::conditional_t<std::is_same_v<T, DoubleTag>, AbstractBaseFloatTag,
        std::conditional_t<std::is_same_v<T, ByteArrayTagPtr>, AbstractBaseArrayTag,
        std::conditional_t<std::is_same_v<T, StringTag>, AbstractBaseImmutableTag,
        std::conditional_t<std::is_same_v<T, ListTagPtr>, AbstractBaseMutableTag,
        std::conditional_t<std::is_same_v<T, CompoundTagPtr>, AbstractBaseMutableTag,
        std::conditional_t<std::is_same_v<T, IntArrayTagPtr>, AbstractBaseArrayTag,
        std::conditional_t<std::is_same_v<T, LongArrayTagPtr>, AbstractBaseArrayTag,
        void
    >>>>>>>>>>>> {
        public:
            T tag;
            TagWrapper(T tag): tag(tag) {};
            virtual std::string to_nbt(std::string name, std::endian endianness, Amulet::StringEncode string_encode) const {
                return Amulet::write_nbt(name, tag, endianness, string_encode);
            }
            virtual std::string to_snbt() const {
                if constexpr (is_shared_ptr<T>::value){
                    return Amulet::write_snbt(*tag);
                } else {
                    return Amulet::write_snbt(tag);
                }
            }
            virtual std::string to_snbt(const std::string& indent) const {
                if constexpr (is_shared_ptr<T>::value){
                    return Amulet::write_formatted_snbt(*tag, indent);
                } else {
                    return Amulet::write_formatted_snbt(tag, indent);
                }
            }
    };
    typedef TagWrapper<ByteTag> ByteTagWrapper;
    typedef TagWrapper<ShortTag> ShortTagWrapper;
    typedef TagWrapper<IntTag> IntTagWrapper;
    typedef TagWrapper<LongTag> LongTagWrapper;
    typedef TagWrapper<FloatTag> FloatTagWrapper;
    typedef TagWrapper<DoubleTag> DoubleTagWrapper;
    typedef TagWrapper<ByteArrayTagPtr> ByteArrayTagWrapper;
    typedef TagWrapper<StringTag> StringTagWrapper;
    typedef TagWrapper<ListTagPtr> ListTagWrapper;
    typedef TagWrapper<CompoundTagPtr> CompoundTagWrapper;
    typedef TagWrapper<IntArrayTagPtr> IntArrayTagWrapper;
    typedef TagWrapper<LongArrayTagPtr> LongArrayTagWrapper;

    typedef std::variant<
        std::monostate,
        ByteTagWrapper,
        ShortTagWrapper,
        IntTagWrapper,
        LongTagWrapper,
        FloatTagWrapper,
        DoubleTagWrapper,
        ByteArrayTagWrapper,
        StringTagWrapper,
        ListTagWrapper,
        CompoundTagWrapper,
        IntArrayTagWrapper,
        LongArrayTagWrapper
    > WrapperNode;

    WrapperNode wrap_node(Amulet::TagNode node);
    Amulet::TagNode unwrap_node(WrapperNode node);
}
