# ⚠️ REQUIRED ASSETS DIRECTORY (`required-assets`)

This directory serves as a **placeholder** for the artifacts and binaries necessary for the deployment of the lab or product.

## 🛑 IMPORTANT NOTE: Licensed Content

The content typically residing in this directory (e.g., container images, Helm Charts, setup binaries) is **NOT included** in this repository due to licensing restrictions.

This material must be sourced and provided by the end-user.

## 📥 Download Instructions

For the successful execution of the lab, users must download the licensed assets directly from the vendor:

1.  **Download Source:**
    * **HCL Software Customer Download Portal (HCL Downloads)**.
2.  **Credentials:**
    * A **valid customer user ID** with the appropriate licenses is required to access and download the licensed material.

## ⚙️ Expected Content Structure (Placeholder)

Once downloaded, the required assets should be placed inside this directory (`required-assets/`) so that deployment scripts or Helm references can locate them.

**Example of files expected to be placed here:**

| File/Element | Description |
| :--- | :--- |
| `product-image.tar.gz` | Primary container image archive. |
| `helm-chart-vX.Y.Z.tgz` | Official Helm Chart required for the deployment. |
| `additional-binary.zip` | Any other required binary or auxiliary resource. |

**Purpose:**

This empty directory acts as a **reference point** and **target destination** for the files, ensuring the repository structure is ready for the installation steps.