# Shift Exchange

The domain request and approval service remain authoritative. The SCE Phase 1
page is a read-only request workspace with deterministic filtering. Request
creation, persistence, conflict checks, canonical schedule mutation,
notifications and Calendar resynchronization belong to Phase 4 and must be
wired through the composition root rather than added directly to widgets.
