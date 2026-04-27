//! Internal broadcast plumbing — not part of the bridge API surface
//! (codegen does not scan this module).

use chess_core::api::BackendEvent;
use chess_core::platform::EventSink;
use parking_lot::RwLock;

pub(crate) type Sender = Box<dyn Fn(BackendEvent) + Send + Sync + 'static>;

#[derive(Default)]
pub(crate) struct BroadcastSink {
    senders: RwLock<Vec<Sender>>,
}

impl BroadcastSink {
    pub(crate) fn attach(&self, sender: Sender) {
        self.senders.write().push(sender);
    }
}

impl EventSink for BroadcastSink {
    fn emit(&self, event: BackendEvent) {
        let senders = self.senders.read();
        for sender in senders.iter() {
            (sender)(event.clone());
        }
    }
}

pub(crate) static BROADCAST: once_cell::sync::OnceCell<std::sync::Arc<BroadcastSink>> =
    once_cell::sync::OnceCell::new();
