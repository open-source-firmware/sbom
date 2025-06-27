.. SPDX-License-Identifier: CC-BY-4.0

.. _chapter-introduction:

Introduction
============

Purpose and Scope
-----------------

Due to the increasing number of high-profile supply chain attacks, it has become more important to
record information about critical software such as system and peripheral firmware.
For US companies, `Executive Order 14028 <https://www.nist.gov/itl/executive-order-14028-improving-nations-cybersecurity>`_
“Improving the Nation's Cybersecurity” and the `Cyber Trust Mark <https://www.fcc.gov/cybersecurity-certification-mark>`_
now make providing an SBOM with this information a legal obligation for many companies.

It has traditionally been difficult to build firmware or platform SBOMs for systems due to the
involvement of three separate entities: the *Firmware Vendor* that produces the bulk of the *source code*,
the ODM (Original Design Manufacturer) that compiles it with other additional code and adds additional
binaries, and the OEM (Original Equipment Manufacturer) that may add their own extensions and then
distributes the firmware.

Most consumer laptop and desktop devices also have many other firmware blobs of firmware supplied for
factory burn-in, e.g. fingerprint reader, SD card reader, touchpad, PCI retimer, Synaptics MST,
Intel Thunderbolt, and many more – and these might not have any communication channel to the system
firmware at all.

End-users do not buy “firmware” and any firmware deliverable will normally be included in a larger
OEM per-device *platform SBOM*.
At the same time, we also need to provide access to the runtime “current firmware SBOM” so that we
can use newer technologies such as `VEX <https://www.cisa.gov/sites/default/files/publications/VEX_Use_Cases_Document_508c.pdf>`_
to automatically identify systems that require security fixes.

This document explains why SBOM metadata for all constituent *components* should be embedded in all
*firmware*, what should be included in it, **and** how it should be used as part of a larger
*platform SBOM* that is useful to end-users.

The purpose of this document is to present a set of guidelines and best practices for vendors of
firmware to provide Software Bill of Materials (SBOM) information to their clients and customers,
to aid in vulnerability detection and license management.

With these sets of recommendations we feel sure that the resulting firmware SBOM will be useful to
security teams and end-users alike.
This would greatly benefit the entire firmware ecosystem and make the global supply chain measurably
safer.

Definition of Terms
-------------------

This document assumes a working knowledge of terminology related to firmware, and of software
concepts such as “libraries” and “compilers”.
The terms defined in this glossary may appear in italics as a reminder that they are being used as
defined here.

Readers may be expecting to see terms like “IBV” (Independent BIOS Vendor), “ODM” (Original Design
Manufacturer), “IFV” (Independent Firmware Vendor) and “OEM” (Original Equipment Manufacturer),
but this document mostly avoids those terms.
This is because those entities may, at any given moment and in any given commercial arrangement,
be acting as *component vendors*, *firmware vendors* or *platform vendors* in the context of this document.

The keywords "**MUST**", "**MUST NOT**", "**REQUIRED**", "**SHALL**", "**SHALL NOT**", "**SHOULD**",
"**SHOULD NOT**", "**RECOMMENDED**",  "**MAY**", and "**OPTIONAL**" in this document should be
interpreted as described in `RFC 2119 <https://www.rfc-editor.org/rfc/rfc2119>`_.

.. glossary::

   SBOM
       Software Bill of Materials: A formal document which can be used to articulate what components
       are contained within a binary deliverable, and who is responsible for each part.

   Component
       Any identifiable, discrete element of a firmware, including but not limited to any item that
       can be removed from, replaced in or added to a file volume or archive.
       This includes, but is not limited to, PE files, PEIMs, CPU microcodes, CMSE/PSP, FSP/AGESA,
       EC and OptionROMs – but **SHOULD NOT** include encryption keys or source code references.
       Each component may be provided as a precompiled binary by a *component vendor* to a
       *firmware vendor*, or it may be built from an independent source code tree by the *firmware vendor*.

   Component SBOM
       A SBOM for a single *component*.

   Component Vendor
       The party responsible for directly supplying a *component* for use by a *firmware vendor* in
       a firmware image.

   Firmware
       Complete firmware image, which typically comprises multiple *components*..

   Firmware SBOM
       The SBOM that represents all the *components* present in a single *firmware* and which could
       be generated in full or in part by combining *component* SBOMs.

   Firmware Vendor
       The party responsible for building *firmware*, for use by the *platform vendor*.

   Platform SBOM
       The SBOM that represents all the components in use on a real-world device.
       This may be equivalent to the *firmware SBOM* for single system firmware deployed on a device,
       or be a superset that includes metadata for multiple firmware (e.g. separate firmware for the
       system and for an attached touchpad or camera device).

   Platform Vendor
       The party responsible for supplying a combined platform firmware image, typically comprising
       multiple firmware, for use on end-user hardware.

   Source Code
       Text written in a program language (for example, C, assembly or Rust) that is compiled into
       binary object files and is not included verbatim in the firmware image.
