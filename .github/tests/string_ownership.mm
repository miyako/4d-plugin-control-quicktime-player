// Exercise the real plugin and SDK; only the 4D engine boundary is simulated.
#include "4DPlugin-Control-QuickTime-Player.cpp"
#include "PrivateTypes.h"
#include "EntryPoints.h"
#include "ARRAY_TEXT.h"
#include "C_TEXT.h"
#include <cassert>
#include <cstdlib>
#include <cstring>
#include <set>

namespace {
bool allocatedEmpty;
std::set<PA_Unichar *> strings;
std::map<PA_Handle, size_t> handles;
struct Node {
    size_t refs = 1;
    std::map<CUTF16String, PA_Variable> properties;
    std::vector<PA_Variable> elements;
};
std::set<Node *> nodes;

CUTF16String contents(PA_Unistring value) {
    if (!value.fString) {
        assert(value.fLength == 0);
        return {};
    }
    PA_Unichar *buffer = value.fString;
    assert(strings.count(buffer));
    assert(value.fString[value.fLength] == 0);
    return CUTF16String(value.fString, value.fLength);
}

PA_Unistring makeString(const CUTF16String &text) {
    PA_Unistring result = {};
    result.fLength = static_cast<PA_long32>(text.size());
    if (allocatedEmpty || !text.empty()) {
        result.fString = static_cast<PA_Unichar *>(
            malloc((text.size() + 1) * sizeof(PA_Unichar)));
        assert(result.fString);
        memcpy(result.fString, text.c_str(), (text.size() + 1) * sizeof(PA_Unichar));
        PA_Unichar *buffer = result.fString;
        assert(strings.insert(buffer).second);
    }
    return result;
}

void freeString(PA_Unistring value) {
    if (value.fString) {
        PA_Unichar *buffer = value.fString;
        assert(strings.erase(buffer) == 1);
        free(value.fString);
    }
}

Node *node(void *ref) {
    auto result = static_cast<Node *>(ref);
    assert(nodes.count(result));
    return result;
}

Node *newNode() {
    auto result = new Node;
    nodes.insert(result);
    return result;
}

void clear(PA_Variable &value);
void release(Node *value) {
    assert(nodes.count(value));
    if (--value->refs == 0) {
        for (auto &entry : value->properties) clear(entry.second);
        for (auto &entry : value->elements) clear(entry);
        nodes.erase(value);
        delete value;
    }
}

void clear(PA_Variable &value) {
    switch (value.fType) {
        case eVK_Unistring: freeString(value.uValue.fString); break;
        case eVK_Object:
            if (value.uValue.fObject) release(node(value.uValue.fObject));
            break;
        case eVK_Collection:
            if (value.uValue.fCollection) release(node(value.uValue.fCollection));
            break;
        case eVK_ArrayUnicode: {
            auto data = reinterpret_cast<PA_Unistring *>(*value.uValue.fArray.fData);
            for (PA_long32 i = 0; i <= value.uValue.fArray.fNbElements; ++i)
                freeString(data[i]);
            PA_DisposeHandle(value.uValue.fArray.fData);
            break;
        }
        case eVK_Undefined: case eVK_Boolean: case eVK_Real:
        case eVK_Longint: case eVK_Null: break;
        default: assert(false && "Unimplemented clear contract");
    }
    value = {};
    value.fType = eVK_Undefined;
}

PA_Variable copy(PA_Variable value) {
    switch (value.fType) {
        case eVK_Unistring: value.uValue.fString = makeString(contents(value.uValue.fString)); break;
        case eVK_Object: if (value.uValue.fObject) ++node(value.uValue.fObject)->refs; break;
        case eVK_Collection: if (value.uValue.fCollection) ++node(value.uValue.fCollection)->refs; break;
        case eVK_Boolean: case eVK_Real: case eVK_Longint: case eVK_Null: break;
        default: assert(false && "Unimplemented copy contract");
    }
    return value;
}

void engine(short selector, EngineBlock *eb) {
    switch (selector) {
        case EX_CREATE_UNISTRING: {
            auto input = reinterpret_cast<PA_Unichar *>(eb->fHandle);
            eb->fUniString1 = makeString(CUTF16String(input));
            break;
        }
        case EX_DISPOSE_UNISTRING: freeString(eb->fUniString1); break;
        case EX_SET_UNISTRING: {
            CUTF16String input(reinterpret_cast<PA_Unichar *>(eb->fHandle));
            freeString(eb->fUniString1);
            eb->fUniString1 = makeString(input);
            break;
        }
        case EX_VARIABLE_TO_STRING: {
            auto value = reinterpret_cast<PA_Variable *>(eb->fHandle);
            assert(value->fType == eVK_Unistring);
            contents(value->uValue.fString);
            eb->fUniString1 = value->uValue.fString;
            break;
        }
        case EX_CLEAR_VARIABLE: clear(*static_cast<PA_Variable *>(eb->fPtr1)); break;
        case EX_GET_INFORMATION: eb->fParam2 = 0x1930; break;
        case EX_HANDLE_MANAGER: {
            // EngineBlock is packed to two bytes; STL references need aligned locals.
            PA_Handle handle = eb->fParam1 == 1 ? nullptr : eb->fHandle;
            switch (eb->fParam1) {
                case 1:
                    eb->fHandle = static_cast<PA_Handle>(malloc(sizeof(char *)));
                    *eb->fHandle = static_cast<char *>(calloc(1, std::max<size_t>(1, eb->fParam2)));
                    handle = eb->fHandle;
                    assert(handles.emplace(handle, static_cast<size_t>(eb->fParam2)).second);
                    break;
                case 2:
                    assert(handles.erase(handle) == 1);
                    free(*eb->fHandle);
                    free(eb->fHandle);
                    break;
                case 3:
                    assert(handles.count(handle));
                    *eb->fHandle = static_cast<char *>(realloc(*eb->fHandle, eb->fParam2));
                    handles[handle] = eb->fParam2;
                    break;
                case 5:
                    assert(handles.count(handle));
                    eb->fParam3 = reinterpret_cast<sLONG_PTR>(*eb->fHandle);
                    break;
                case 6: assert(handles.count(handle)); break;
                default: assert(false && "Unimplemented handle operation");
            }
            break;
        }
        case EX_EXECUTE_COMMAND_BY_ID: {
            auto result = static_cast<PA_Variable *>(eb->fPtr2);
            auto args = static_cast<PA_Variable **>(eb->fPtr1);
            switch (eb->fParam1) {
                case 1471: PA_SetObjectVariable(result, newNode()); break;
                case 1472: PA_SetCollectionVariable(result, newNode()); break;
                case 1231: {
                    assert(eb->fParam2 == 2);
                    Node *obj = node(args[0]->uValue.fObject);
                    PA_SetBooleanVariable(result,
                        obj->properties.count(contents(args[1]->uValue.fString)) != 0);
                    break;
                }
                default: assert(false && "Unimplemented command");
            }
            break;
        }
        case EX_SET_OBJ_VALUE: {
            Node *obj = node(eb->fPtr1);
            auto value = static_cast<PA_Variable *>(eb->fPtr2);
            PA_Variable *destination;
            if (eb->fShort == eVK_Object) {
                CUTF16String key = contents(eb->fUniString1);
                auto found = obj->properties.find(key);
                if (found != obj->properties.end()) {
                    clear(found->second);
                    destination = &found->second;
                } else {
                    destination = &obj->properties[key];
                }
            } else {
                assert(eb->fShort == eVK_Collection);
                assert(eb->fLongint >= 0);
                size_t index = static_cast<size_t>(eb->fLongint);
                assert(index <= obj->elements.size());
                if (index == obj->elements.size()) obj->elements.emplace_back();
                else clear(obj->elements[index]);
                destination = &obj->elements[index];
            }
            *destination = copy(*value);
            break;
        }
        case EX_GET_OBJ_VALUE: {
            Node *obj = node(eb->fPtr1);
            auto result = static_cast<PA_Variable *>(eb->fPtr2);
            if (eb->fShort == eVK_Object) {
                *result = copy(obj->properties.at(contents(eb->fUniString1)));
            } else {
                assert(eb->fShort == eVK_Collection);
                if (eb->fLongint == -1) {
                    PA_SetLongintVariable(result, static_cast<PA_long32>(obj->elements.size()));
                } else {
                    *result = copy(obj->elements.at(eb->fLongint));
                }
            }
            break;
        }
        default:
            fprintf(stderr, "Unexpected engine selector: %d\n", selector);
            abort();
    }
    eb->fError = eER_NoErr;
}

void balanced(const char *scenario) {
    if (!strings.empty() || !nodes.empty() || !handles.empty()) {
        fprintf(stderr, "%s leaked: %zu strings, %zu references, %zu handles\n",
                scenario, strings.size(), nodes.size(), handles.size());
        abort();
    }
}

const char *fixtures[] = {"ASCII", "\xE6\x97\xA5\xE6\x9C\xAC", "\xF0\x9F\x98\x80", ""};
const wchar_t *wideFixtures[] = {L"ASCII", L"\u65E5\u672C", L"\U0001F600", L""};
const CUTF16String expectedFixtures[] = {
    CUTF16String({'A','S','C','I','I'}), CUTF16String({0x65E5,0x672C}),
    CUTF16String({0xD83D,0xDE00}), CUTF16String()
};

void checkProperty(PA_ObjectRef obj, const wchar_t *key, const CUTF16String &expected) {
    CUTF16String name;
    json_wconv(key, &name);
    assert(contents(node(obj)->properties.at(name).uValue.fString) == expected);
}

void setters() {
    for (size_t i = 0; i < 4; ++i) {
        PA_ObjectRef obj = PA_CreateObject();
        const CUTF16String &expected = expectedFixtures[i];
        CUTF16String converted;
        json_wconv(wideFixtures[i], &converted);
        assert(converted == expected);
        for (int repeat = 0; repeat < 20; ++repeat) {
            ob_set_s(obj, "narrow", fixtures[i]);
            ob_set_s(obj, L"wide", fixtures[i]);
            ob_set_a(obj, L"wchar", wideFixtures[i]);
            ob_set_a(obj, L"utf16", &expected);
            checkProperty(obj, L"narrow", expected);
            checkProperty(obj, L"wide", expected);
            checkProperty(obj, L"wchar", expected);
            checkProperty(obj, L"utf16", expected);
        }
        PA_DisposeObject(obj);
        balanced("setters");
    }
}

void getters() {
    for (size_t i = 0; i < 4; ++i) {
        PA_ObjectRef obj = PA_CreateObject();
        // Seed without calling a setter under test, isolating getter failures.
        CUTF16String text = expectedFixtures[i];
        PA_Variable value = {};
        value.fType = eVK_Unistring;
        value.uValue.fString = makeString(text);
        node(obj)->properties[CUTF16String({'v'})] = value;
        size_t initial = strings.size();
        for (int repeat = 0; repeat < 20; ++repeat) {
            CUTF8String output;
            assert(ob_get_a(obj, L"v", &output));
            assert(std::string(reinterpret_cast<const char *>(output.c_str()), output.size()) == fixtures[i]);
            assert(!ob_get_b(obj, L"v"));
            assert(ob_get_n(obj, L"v") == 0);
            assert(!ob_get_o(obj, L"v"));
            assert(!ob_get_c(obj, L"v"));
            assert(!ob_get_a(obj, L"missing", &output));
        }
        if (strings.size() != initial) {
            fprintf(stderr, "getters leaked %zu owning property results\n", strings.size() - initial);
            abort();
        }
        ob_set_b(obj, L"v", true);
        assert(ob_get_b(obj, L"v"));
        ob_set_n(obj, L"v", 12.5);
        assert(ob_get_n(obj, L"v") == 12.5);
        PA_ObjectRef nested = PA_CreateObject();
        ob_set_s(nested, "name", "nested");
        ob_set_o(obj, L"object", nested);
        PA_CollectionRef collection = PA_CreateCollection();
        ob_set_c(obj, L"collection", collection);
        PA_ObjectRef returnedObject = ob_get_o(obj, L"object");
        PA_CollectionRef returnedCollection = ob_get_c(obj, L"collection");
        assert(returnedObject && returnedCollection);
        // Scalar mismatches must release references without damaging the property.
        CUTF8String output;
        assert(ob_get_a(obj, L"object", &output));
        assert(!ob_get_b(obj, L"collection"));
        assert(ob_get_n(obj, L"object") == 0);
        assert(!ob_get_c(obj, L"object"));
        assert(!ob_get_o(obj, L"collection"));
        PA_DisposeObject(obj);
        checkProperty(returnedObject, L"name", CUTF16String({'n','e','s','t','e','d'}));
        assert(PA_GetCollectionLength(returnedCollection) == 0);
        PA_DisposeObject(returnedObject);
        PA_DisposeCollection(returnedCollection);
        balanced("getters");
    }
}
}

@interface OwnershipDocument : NSObject
@property(copy) NSString *name;
@end
@implementation OwnershipDocument
@synthesize name;
- (void)dealloc { [name release]; [super dealloc]; }
@end

@interface OwnershipApplication : NSObject
@property(retain) NSArray *documents;
@end
@implementation OwnershipApplication
@synthesize documents;
- (void)dealloc { [documents release]; [super dealloc]; }
@end

namespace {
void documents() {
    auto application = [[[OwnershipApplication alloc] init] autorelease];
    NSMutableArray *docs = [NSMutableArray array];
    for (const char *fixture : fixtures) {
        auto document = [[[OwnershipDocument alloc] init] autorelease];
        document.name = [NSString stringWithUTF8String:fixture];
        [docs addObject:document];
    }
    auto nameless = [[[OwnershipDocument alloc] init] autorelease];
    [docs addObject:nameless];
    application.documents = docs;
    for (int repeat = 0; repeat < 20; ++repeat) {
        PA_ObjectRef status = PA_CreateObject();
        getDocuments(reinterpret_cast<QuickTimePlayerApplication *>(application), status);
        assert(ob_get_b(status, L"success"));
        PA_CollectionRef names = ob_get_c(status, L"names");
        assert(PA_GetCollectionLength(names) == 4);
        PA_DisposeObject(status);
        // Collection and its copied strings must survive clearing locals/status.
        for (size_t i = 0; i < 4; ++i) {
            const CUTF16String &expected = expectedFixtures[i];
            PA_Variable item = PA_GetCollectionElement(names, static_cast<PA_long32>(i));
            assert(contents(PA_GetStringVariable(item)) == expected);
            PA_ClearVariable(&item);
        }
        PA_DisposeCollection(names);
        balanced("documents");
    }
}

void arrays() {
    PA_Variable array = PA_CreateVariable(eVK_ArrayUnicode);
    PA_ResizeArray(&array, 4);
    for (int repeat = 0; repeat < 20; ++repeat) {
        for (size_t i = 0; i < 4; ++i) {
            const CUTF16String &expected = expectedFixtures[i];
            PA_Unistring value = PA_CreateUnistring(const_cast<PA_Unichar *>(expected.c_str()));
            PA_SetStringInArray(array, static_cast<PA_long32>(i), &value);
            assert(contents(PA_GetStringInArray(array, static_cast<PA_long32>(i))) == expected);
        }
    }
    PA_Unichar rejectedText[] = {'r',0};
    PA_Unistring rejected = PA_CreateUnistring(rejectedText);
    PA_SetStringInArray(array, -1, &rejected);
    PA_SetStringInArray(array, 5, &rejected);
    PA_Variable wrong = PA_CreateVariable(eVK_Longint);
    PA_SetStringInArray(wrong, 0, &rejected);
    PA_Variable missingData = {};
    missingData.fType = eVK_ArrayUnicode;
    PA_SetStringInArray(missingData, 0, &rejected);
    assert(contents(rejected) == CUTF16String({'r'}));
    PA_DisposeUnistring(&rejected);
    PA_ResizeArray(&array, 0);
    PA_ClearVariable(&array);
    // Dormant wrapper: copy borrowed input, transfer fresh output allocations.
    array = PA_CreateVariable(eVK_ArrayUnicode);
    unsigned char *parameter = reinterpret_cast<unsigned char *>(&array);
    PackagePtr params = &parameter;
    ARRAY_TEXT output;
    for (const CUTF16String &expected : expectedFixtures)
        output.appendUTF16String(expected.c_str(), static_cast<uint32_t>(expected.size()));
    output.toParamAtIndex(params, 1);
    ARRAY_TEXT input;
    input.fromParamAtIndex(params, 1);
    PA_ClearVariable(&array);
    for (size_t i = 0; i < 4; ++i) {
        CUTF16String actual;
        input.copyUTF16StringAtIndex(&actual, static_cast<uint32_t>(i));
        assert(actual == expectedFixtures[i]);
        C_TEXT scalar;
        scalar.setUTF16String(actual.c_str(), static_cast<uint32_t>(actual.size()));
        PA_Unichar empty[] = {0};
        PA_Unistring destination = PA_CreateUnistring(empty);
        unsigned char *textParameter = reinterpret_cast<unsigned char *>(&destination);
        scalar.toParamAtIndex(&textParameter, 1);
        assert(contents(destination) == expectedFixtures[i]);
        PA_DisposeUnistring(&destination);
    }
    balanced("arrays");
}
}

int main(int argc, char **argv) {
    assert(argc == 3);
    allocatedEmpty = std::string(argv[2]) == "allocated";
    gCall4D = engine;
    @autoreleasepool {
        std::string scenario(argv[1]);
        if (scenario == "setters") setters();
        else if (scenario == "getters") getters();
        else if (scenario == "documents") documents();
        else if (scenario == "arrays") arrays();
        else abort();
        balanced(argv[1]);
    }
    return 0;
}
