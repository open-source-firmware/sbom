.. SPDX-License-Identifier: CC-BY-4.0

.. _chapter-metadata:

Metadata Provided
=================

Introduction
------------

The purpose of an SBOM is to tell the end-user what components make up the software deliverable,
and to give them information on where it was retrieved from or built.
The questions end-users need to be able to answer are “what version of OpenSSL is included, and
where did it come from” and “do I trust all the companies contributing code and binaries to this image”.
Answering the *what* and *who* in a standardized way also allows us to use other specifications such as VEX.

In this section we use the term “SBOM component” to refer to a single ingredient within an SBOM
(in a coSWID SBOM, this is a single tag).

Each SBOM component **SHOULD** describe either:

- A single *component*, as defined in the glossary, or
- An individually identifiable part of a *component* that has security and/or licensing implications,
  for example an image loading library used by a PE binary, or
- Something that has security and/or licensing implications and was used to produce a *component*
  but is not present in the *component* itself, for example a compiler used to produce a PE binary, or
- Any kind of defined logical component, for example “optional features” or “value add” options that
  may be matched from a VEX file (see below).

Each *component* **MUST** be represented by an SBOM component in its *component SBOM*, or the
*firmware SBOM* if the component does not have its own SBOM.
Libraries, compilers etc. **SHOULD** be represented by SBOM components (see the `Component Relationships`_
section below for more on this).
Thus, a *component SBOM* or *firmware SBOM* **MUST** contain at least one tag, and **MAY** contain more.

For components or relationships that cannot currently be disclosed for legal reasons, vendors **MAY**
use the literal text ``REDACTED`` in place of the correct string value.
This is intended as a **temporary** measure while contracts or NDAs are renegotiated.
Any SBOM components with ``REDACTED`` text **MAY** be marked as incomplete and **MUST** fail validation.

Required Attributes
-------------------

Each tag:

- **MUST** have an identifier in the form of a GUID.
  See the `Identifier`_ section below for more details.
- **MUST** have a non-zero length descriptive name, e.g. “CryptoDxe”, and **SHOULD NOT** include a file extension as this is already included in the SWID payload section.
- **MUST** have at least one entity entry and **SHOULD** have more than one, if more than one legal entity is involved in its creation, maintenance and/or distribution.
   - One entity **MUST** have the tag-creator role.
   - One entity **MUST** have the software-creator role, and it **MAY** be the same entity as the one specified in tag-creator.
     See the `Vendor Entity`_ section below for details.
   - In specifying entity roles, vendors **SHOULD** be careful not to make business relationships public that are not already in the public domain.
- **MUST** have a version, which **SHOULD** be a semantic version like ``1.2.3``.
- **SHOULD** have a revision if the component has been modified by downstream patches. If supplied the revision **SHOULD** have the form``{release}.{dist}`` . The ``release`` is an unsigned integer, and ``dist`` is a lowercase short vendor name, e.g. ```1.hughski`` or ``999.redhat``.
- **MUST** have a file hash that is generated from all the source files, if it is a binary built from *source code* or other constituent parts. This **MUST** be either a SHA-1 or SHA-256 hash.
   - This is what uSWID calls a “colloquial version.”
- **SHOULD** have a source control tree hash which **MUST** be either a SHA-1 or SHA-256 hash (e.g. the output from ``git describe``), if it is a binary built from *source code* under source control.
   - This is what uSWID calls an “edition.”
- **MAY** or **MUST** include one or more link entries expressing relationship(s) to another SBOM component. See the `Component Relationships`_ section below for details, including when link entries are **REQUIRED** and when they are **OPTIONAL**.

The file hash **SHOULD** include the hashes of the *source code* files used to construct the binary, such as ``.c`` and ``.h`` files.
Any library statically-linked with the PE binary **SHOULD** be included as an additional SBOM component.


Identifier
----------

In some cases, the most obvious identifier to use for the SBOM component is already in a GUID form – for instance using the UEFI GUID defined in an official specification or reference implementation.
In other cases, like GCC (where there is no GUID defined), vendors **MUST** use a ``swid:`` prefix to generate a GUID that is linked within the object.
Using a GUID is deliberate because it can obscure internal references, and can be encoded as a 128-bit number in coSWID.

Example component IDs could include:

- ``swid:intel-microcode-706E5-80``
- ``swid:gcc``
- ``f43cae5a-baea-5023-bc90-3a83cd4785cc which is UUID(DNS, “gcc”)``

Some of this information is already present in projects such as EDK2 in the various ``.inf`` files.

*Firmware vendors* and *component vendors* **SHOULD** consult with any upstream projects before deciding identifier GUIDs.

Forked components modified by the *firmware vendor* **MUST** have an identifier different from the upstream component identifier.

The identifier GUID:

* **SHOULD NOT** include the component version, file or tree hash or revision.
* **MAY** allow comparing some components against SBOMs from different vendors.


Vendor Entity
-------------

An “entity” describes a party responsible for the creation, maintenance, and/or distribution of a firmware or component.
An entity can perform one or more roles (e.g. creator, maintainer and distributor), and multiple entities (even with the same role) can be defined for each component.

For instance, Intel FSP is created by Intel, maintained by Intel, and distributed by Intel.
A modified DXE might originally be created by Intel in EDK2, but then be modified and maintained by AMI and distributed by Lenovo.
In this case, the component for the FSP would have only one entity entry, but the component for the DXE would have three entity entries.

For each entity entry:

* The name **MUST** be the legal or common-use name of the open-source project, the component vendor, the firmware vendor, or the platform vendor.
* The registration ID **MUST** be the DNS name of the named legal entity, or the DNS name of the upstream project URL in the case of open-source projects.


Component Relationships
-----------------------

SBOM component links are used to supply additional information about how components relate to each other.
They also include any required licensing information, statically linked libraries and links to additional resources.
Libraries that may be matched from a VEX file (for instance, where a third-party library has previously security vulnerabilities) **SHOULD** be included as a component, but other internal libraries **MAY** be omitted.
SBOM components **MAY** use multiple links, even of the same relationship type.

- SBOM components representing open-source software **MUST** include one or more license link(s) indicating all licenses that apply.
   - The URL for each license link **MUST** be the SPDX license URL, e.g.: ``https://spdx.org/licenses/LGPL-2.1-or-later.html``
   - The ``license`` relationship type **MUST** be used.
   - All open-source code **SHOULD** be identified with its own SBOM component to allow verification of license compliance.
- SBOM components representing non-open-source software **SHOULD** include one or more license link(s) indicating all licenses that apply.
   - The URL for each license link **MUST** be a public webpage with the full text of the proprietary license.
   - The ``license`` relationship type **MUST** be used.
- SBOM components representing compiled binaries **SHOULD** reference SBOM components representing the compiler and linker used to build the binary where possible.
   - The ``see-also`` relationship type **MUST** be used, and the ``swid``-prefixed URL **MUST** be an existing component identifier defined in the component or firmware SBOM.
- SBOM components representing compiled binaries **SHOULD** reference SBOM components representing libraries that are linked into the binary and that may be referenced in VEX documents (see below).
   - The ``requires`` relationship type **MUST** be used, and the ``swid``-prefixed URL **MUST** point to an existing component in the SBOM.
- SBOM components **MAY** include a link specifying the source URL where they can be downloaded. e.g. ``https://github.com/intel/FSP/AmberLakeFspBinPkg``
   - The ``installationmedia`` relationship type **MUST** be used.
