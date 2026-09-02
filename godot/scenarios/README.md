# Scenarios

Data and assets specific to each builder scenario belong here.

`ancient_egypt/entities.json` is kept byte-for-byte equal to the active legacy
definition file during the parity milestone. The Python parity tests enforce
that synchronization.

The version 1 saves under `ancient_egypt/fixtures/` are also byte-for-byte
copies of the bundled Python saves. They exercise real active processes,
in-flight packets, empty returns, ID gaps, construction, and settlement state.
