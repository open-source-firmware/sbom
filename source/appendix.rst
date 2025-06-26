.. SPDX-License-Identifier: CC-BY-4.0

.. _chapter-appendix:

Appendix
========

External SBOM Metadata
----------------------

This document strongly encourages vendors to embed the SBOM metadata into the respective binaries, but there are two situations where externally referenced SBOM metadata would be allowed:

- Where the binary is loaded onto critically space-constrained devices, for example microcode that is loaded into the processor itself.
- Where only later newer versions of the component have embedded SBOM metadata, and backwards compatibility is required with older revisions.

In these cases, the *component vendor* **MUST** provide “detached metadata” from the same source (or in the same archive file) as is used to distribute the immutable blob.

As the SBOM metadata is detached, vendors **MUST** ensure that the files do not get “out of sync” and are updated at the same time in the firmware source tree.
Detached metadata **MUST** `always contain the SHA256 hash value of the binary <https://github.com/hughsie/python-uswid/#use-cases>`_ as evidence to allow validation and **MAY** be signed using a detached signature if the archive is not already signed.
The public key **SHOULD** be distributed on a keyserver or company website for verification.


Wasted Space Concerns
---------------------

Some vendors have expressed concerns about “wasted” space from including the SBOM data in the binary image.
For source components such as CPU microcode, a single *component* and vendor *entity* would use an additional ~350 bytes (zlib compressed coSWID), compared to 48kB for the average EFI binary and 25kb for a typical vendor BGRT “splash” logo.

The ``uswid`` command can automatically `generate <https://github.com/hughsie/python-uswid#generating-test-data>`_ a complete “worst case” platform SBOM with 1,000 plausible components.
This SBOM requires an additional 140kB of SPI flash space (uncompressed coSWID), or 60kB when compressed with LZMA.
For reference, the average free space in an Intel Flash ROM BIOS partition is 5.26Mb, where “free space” is defined as a greater than 100KiB stream of consecutive 0xFF’s after the first detected EFI file volume.
Adding the SBOM as embedded metadata would use 1.1% of the available free space.
Other firmware ecosystems such as Coreboot also `now include SBOM generation <https://doc.coreboot.org/sbom/sbom.html>`_ as part of the monolithic image.


Getting the Runtime SBOM
------------------------

The ACPI ``SBOM`` ACPI table may be used in the future to return the coSWID formatted binary SBOM data from any device exporting an ACPI callable interface.
Further details will be provided when the SBOM table has been implemented.

If the platform allows direct access to the system SPI device, then the entire firmware image can be dumped to a local file and analyzed by tools such as ``uswid``.

Converting the SBOM
-------------------

The embedded SBOM **SHOULD** be converted it into one or more SBOM export formats before publication.

This can be achieved easily using tools such as ``uswid``.
For example, this can be used to produce two JSON files in CycloneDX and SPDX formats from the platform image:

::

  $ uswid --load rom.bin --save cyclonedx-bom.json
  $ uswid --load rom.bin --save spdx.json

Signing the SBOM
----------------

The embedded SBOM **MAY** be signed, and **MAY** also be included in the firmware checksum.
If the firmware component is signed then the SBOM **SHOULD** be included in to the signature.
The signing step is optional because a malicious silicon provider can typically do much worse things (e.g. adding or replacing a DXE binary) than modify the SBOM metadata.

Using the LVFS
--------------

When firmware is uploaded to the LVFS it automatically extracts all available SBOM metadata and generates `a HTML page <https://fwupd.org/lvfs/devices/component/64327/swid>`_ with SPDX, SWID and CycloneDX download links that can be used for compliance purposes.
The LVFS **MAY** allow vendors to upload firmware or platform SBOMs without uploading the firmware binary.
Other services like Windows Update may offer this service in the future.

The VEX "trusted neutral entity" **MAY** also be the LVFS, even for firmware updates not distributed by the LVFS.
Uploading VEX data requires vendors to register `for a LVFS vendor account <https://lvfs.readthedocs.io/en/latest/apply.html>`_ which is available at no cost.
