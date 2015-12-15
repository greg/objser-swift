# CHANGELOG

## 0.2

Correct deserialisation of object graphs containing cycles.

- **[BREAKING]** The `Serialisable` protocol separates `createByDeserialising` into `createForDeserialising` and `deserialiseFrom`, due to the impossibility of obtaining a value for an object before `init` completes, a necessity for recreating cyclic graphs.
- The `AcyclicSerialisable` protocol has been added with a single `createByDeserialising` function; however, it operates on the guarantee that the object is not part of a cycle.
- `InitableSerialisable` remains the same, with the added requirement of the object not being part of a cycle.

## 0.1

Initial release

