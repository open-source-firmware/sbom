.. SPDX-License-Identifier: CC-BY-4.0

.. _chapter-embedding:

Embedding
=========

Introduction
------------

When we talk about “embedding the SBOM”, we refer to the general idea of having SBOM metadata for
all *components* in a given *firmware* included into the firmware image itself, either by providing
a *firmware SBOM* or just by ensuring all components are represented in multiple *component SBOMs*.

Traditionally there has been pressure to keep firmware images as small as possible to minimize SPI
storage space and to minimize the cost of the *Hardware Bill of Materials*.
While this is a noble aim, sacrificing a few hundred bytes of space for an embedded SBOM has several
advantages:

- The SBOM does not need to be verified against a binary deliverable, it can be assumed to be
  “part of” the existing source artefact itself.
- Vendors at any link in the supply chain that don’t care about or understand SBOMs do not “strip”
  the SBOM information.
- The *component SBOMs and/or firmware SBOMs* from all the factory burn-in *firmware* images can be
  combined into one generated public *platform SBOM* that can be used for contractual or compliance
  reasons, without the need to request *component* or *firmware* SBOMs separately from each
  *component vendor* and *firmware vendor*.
- Build-time automated embedding as part of CI/CD is recommended as part of the
  `US Cyber Trust Mark <https://www.osfc.io/2023/talks/us-cyber-trust-mark-is-your-firmware-ready/>`_ initiative.
- Some firmware build systems require the firmware blob and definition files to be put in a
  predefined place to generate a new firmware binary, which means non-embedded SBOM metadata may get
  out-of-sync with the blob.

If the SBOM is not embedded as a build artifact, a firmware engineer could rebuild the firmware
capsule and forget to also regenerate or replace the SBOM in the new archive because it is a separate
process that is hard to verify was done.
If the SBOM is part of the image itself and *automatically constructed* as part of the deliverable,
then it is impossible to forget.
Sending the capsule or manually dumped ROM image to a QA engineer means they can know with almost
complete certainty what blobs the image was built with.
Embedding the SBOM makes doing the "right" thing easy and doing the "wrong" thing hard.

General Best Practices
----------------------

All *component vendors* **SHOULD** embed an SBOM in the component image, formatted as described below.
They **MAY** also create a more detailed detached SBOM (for instance referencing internal issues or
*source code* filenames) that **MAY** be provided to the *firmware vendor* under NDA.

*Firmware vendors* **SHOULD** ensure embedded SBOM metadata is included for every PE binary and all
additional *components* included in the *firmware* formatted as described below.
This **MUST** be done by:

- Including the SBOM for each *component* in a “defragmented” *firmware SBOM* created at build time, **OR**
- Ensuring that each *component* contains embedded SBOM metadata, **OR**
- Doing both of the above.

*Component* and *firmware* SBOMs **SHOULD NOT** reference any code or blobs which are not actually
present, or which have been disabled in the system.

Embedded SBOM Formats
---------------------

*Firmware* and *component vendors* **MUST** use the `DTMF coSWID <https://datatracker.ietf.org/doc/rfc9393/>`_
binary format with CBOR encoding when directly embedding SBOM sections in firmware.
This format was chosen due to the small compiled size of data compared to `SPDX <https://spdx.dev/use/specifications/>`_
(YAML or JSON) and `SWID <https://www.iso.org/standard/65666.html>`_ (XML), because the specification
is freely available and because it can act as a superset format to both SPDX and CycloneDX.


Built Portable Executable (PE) Binaries
---------------------------------------

Most *components* in a typical *firmware* are compiled from *source code* and linked into PE binaries.
These can be considered components whose vendor is the *firmware vendor*.

The *firmware vendor* **SHOULD** ensure that the SBOM metadata is automatically built and verified
at compile time and then added to the PE binary (in the ``.sbom`` COFF section), placed directly in
the “defragmented” *firmware SBOM* (see below), or both.
If for any reason this is not done automatically at compile time, the *firmware vendor* still **MUST**
ensure the SBOM is included in the binary ``.sbom`` COFF section or the “defragmented” *firmware SBOM*,
as required above.

For Tianocore/EDK2 firmware, there is an `example <https://github.com/hughsie/uswid-uefi-example>`_
showing how to supplement the information in the ``.inf`` file with per-component and per-platform
overrides.
More specific recommendations on how to include additional artifacts into the ``.sbom`` section have
not been made as this will be heavily influenced by the existing proprietary build system and tools
used to build the image.

In the case where there is no natural place to store the *component SBOM*, it **SHOULD** be included
as a per-volume metadata section. In this case it **MUST** include a uSWID magic header, as described
in `Components that are not Portable Executables (PE)`_ below.


Precompiled Portable Executable (PE) Binaries
---------------------------------------------

*Firmware vendors* do not have to compile all the PE binaries in the EFI volume from *source code*.
They may get pre-compiled and pre-signed binaries from third-party *component vendors*.
*Component vendors* **SHOULD** include the coSWID SBOM metadata for these components in a ``.sbom``
`COFF <https://learn.microsoft.com/en-us/windows/win32/debug/pe-format>`_ section which can be easily
included at link time.
These binaries **MUST NOT** use the magic header of uSWID (described below) as the PE header can be
parsed for the correct offset of the section.

An additional benefit of including the SBOM in a COFF section is that it is verified by the existing
`Authenticode digital signature <https://learn.microsoft.com/en-us/windows-hardware/drivers/install/authenticode>`_.

If a *firmware vendor* uses a PE binary which does not have this embedded SBOM metadata, the
*firmware vendor* **MUST** ensure SBOM metadata for the binary is present in a “defragmented”
firmware SBOM, as described below.


Components that are not Portable Executables (PE)
-------------------------------------------------

When embedding SBOM metadata into any binary that is not a Portable Executable  (PE),
the *component vendor* **MUST** use the `discoverable uSWID header <https://github.com/hughsie/python-uswid#coswid-with-uswid-header>`_
so that software can easily discover the embedded SBOM.
The 25-byte uSWID header is listed below:

::

  uint8_t[16]   magic, "\x53\x42\x4F\x4D\xD6\xBA\x2E\xAC\xA3\xE6\x7A\x52\xAA\xEE\x3B\xAF"
  uint8_t       header version, typically 0x03
  uint16_t      little-endian header length, typically 0x19
  uint32_t      little-endian payload length
  uint8_t       flags
                  0x00: no flags set
                  0x01: compressed payload
  uint8_t       payload compression type
                  0x00: none
                  0x01: zlib
                  0x02: lzma

The header length **MAY** be increased for alignment reasons (e.g. to 0x100 bytes), and in this case
the additional header padding **MUST** be ``NUL`` bytes.

The uSWID payload **SHOULD** be compressed with either zlib or LZMA, and a firmware image containing
the binary **SHOULD** `pass validation <https://github.com/hughsie/python-uswid/pull/58>`_ using
``uswid``, for example:

::

  $ uswid --load firmware.bin --validate
  Found USWID header at offset: 0x18000
  Validation problems:
  dd4bbe2e40ba          component: No software name (uSWID >= v0.4.7)
  dd4bbe2e40ba             entity: Invalid regid http://www.hughsie.com,   should be DNS name hughsie.com (uSWID >= v0.4.7)
  dd4bbe2e40ba             entity: No entity marked as TagCreator (uSWID >= v0.4.7)
  dd4bbe2e40ba            payload: No SHA256 hash in FSPS (uSWID >= v0.4.7)
  dd4bbe2e40ba             link: Has no LICENSE (uSWID >= v0.4.7)
  dd4bbe2e40ba             link: Has no COMPILER (uSWID >= v0.4.7)

Although there are many tools for the distribution of the *firmware SBOM* to end-users, fewer tools
exist to embed SBOMs into binary blobs, or to extract and merge SBOM components to build a
*firmware SBOM* or *platform SBOM*. The `python-uswid <https://github.com/hughsie/python-uswid>`_
project is one such tool.


Defragmented firmware SBOM
--------------------------

A firmware image can contain a “defragmented” top-level *firmware SBOM* with a uSWID header,
produced at build time. If each *component* in the image has uSWID metadata, coSWID data in PE/COFF
``.sbom`` sections and/or file volumes with uSWID metadata, the *firmware vendor* **MAY** omit this
*firmware SBOM*. If not, the *firmware vendor* **MUST** include it.

If the *firmware SBOM* is present:

- It **MUST** contain all *component SBOMs* present in the image.
  This requirement is to ensure that tools do not need to combine and deduplicate *component SBOMs*
  with the *firmware SBOM* to provide all available information.
- It **SHOULD** be compressed.
- The components **MAY** also have *component SBOMs* as described in this document, to allow them to
  be analyzed in isolation.
