#![allow(clippy::vec_box)]

use spdk_sys::spdk_bdev_module;

use crate::bdev::nexus::{nexus_bdev::Nexus, nexus_fn_table::NexusFnTable};

/// Allocate C string and return pointer to it.
/// NOTE: The resulting string must be freed explicitly after use!
macro_rules! c_str {
    ($lit:expr) => {
        std::ffi::CString::new($lit).unwrap().into_raw();
    };
}

pub mod nexus_bdev;
pub mod nexus_bdev_children;
pub mod nexus_bdev_rebuild;
mod nexus_channel;
pub(crate) mod nexus_child;
pub(crate) mod nexus_child_error_store;
mod nexus_config;
pub mod nexus_fn_table;
pub mod nexus_io;
pub mod nexus_iscsi;
pub mod nexus_label;
pub mod nexus_metadata;
pub mod nexus_metadata_content;
pub mod nexus_module;
pub mod nexus_nbd;
pub mod nexus_nvmf;
pub mod nexus_share;

/// public function which simply calls register module
pub fn register_module() {
    nexus_module::register_module()
}

/// get a reference to the module
pub fn module() -> Option<*mut spdk_bdev_module> {
    if let Some(m) = nexus_module::NexusModule::current() {
        Some(m.as_ptr())
    } else {
        None
    }
}

/// get a static ref to the fn table of the nexus module
pub fn fn_table() -> Option<&'static spdk_sys::spdk_bdev_fn_table> {
    Some(NexusFnTable::table())
}

/// get a reference to the global nexuses
pub fn instances() -> &'static mut Vec<Box<Nexus>> {
    nexus_module::NexusModule::get_instances()
}

/// function used to create a new nexus when parsing a config file
pub fn nexus_instance_new(name: String, size: u64, children: Vec<String>) {
    let list = instances();
    list.push(Nexus::new(&name, size, None, Some(&children)));
}
