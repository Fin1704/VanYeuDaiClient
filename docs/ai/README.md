# Persistent Project Knowledge Base

Snapshot phân tích: **2026-11-03**, working tree local. Viết cho agent cần định vị code nhanh; source hiện tại là nguồn sự thật cuối cùng. Phạm vi và validation xem [analysis coverage](analysis-coverage.md). Không lấy release tag hay README lịch sử làm bằng chứng runtime của working tree này.

## Bắt đầu theo task

1. Đọc [AGENTS.md](../../AGENTS.md), tìm hàng liên quan trong [module index](module-index.md).
2. Chỉ nạp tài liệu module đó và dependency liên quan; mở đúng source/symbol trước khi sửa.
3. Kiểm tra [known issues](known-issues.md), chọn [tests phù hợp](modules/testing.md), cập nhật những trang bị tác động sau thay đổi.

| Cần tìm | Đọc |
| --- | --- |
| Entry/engine/export/InputMap | [Project runtime](modules/project-runtime.md) |
| Ranh giới 3D và 2D | [Architecture](architecture.md) |
| Chọn module/file | [Module index](module-index.md) |
| Caller/callee, shared contracts | [Dependencies](dependencies.md) |
| Seal/boss/checkpoint, damage, skills, corpse, persistence | [Data flows](data-flows.md) |
| Quy tắc code/error/lifecycle | [Conventions](conventions.md) |
| Quyết định đã triển khai, lý do có bằng chứng | [Decisions](decisions.md) |
| Debt, mismatch và rủi ro chưa tái hiện | [Known issues](known-issues.md) |
| Đã đọc gì, thiếu gì, cần tiếp tục ở đâu | [Analysis coverage](analysis-coverage.md) |
| Symbol/line/hash từng file | [Source inventory JSON](source-inventory.json) — tra theo path, không nạp hết nếu không cần |

## Duy trì và tiếp tục

Code thay đổi => chỉ sửa các module, dependency/data flow/issue/decision bị ảnh hưởng. Ghi path + symbol, phân biệt VERIFIED_STATIC, VERIFIED_RUNTIME và UNVERIFIED; không thêm ý tưởng chưa triển khai vào mô tả behavior. Đối chiếu hash/đọc source để xử lý tài liệu lỗi thời; không dùng hash thay cho review.

Nếu phải dừng giữa chừng: cập nhật analysis-coverage với batch, file/range đã đọc, kết luận đã lưu, câu hỏi chưa rõ và bước tiếp theo. File có trạng thái chưa đọc không được tính vào tổng phân tích. Khi thêm/xóa source, cập nhật source-inventory và mapping module, rồi chạy validator. Không viết lại toàn bộ knowledge base cho sửa nhỏ.

Tài liệu có sẵn được giữ: [documentation index gốc](../README.md), [development](../DEVELOPMENT.md), [Stillwater](../STILLWATER.md), [game plan](../../documents/game_plan.md). Các spec/plan có ngày và archive 2D là lịch sử/ý định, chỉ dùng như context, đối chiếu source trước khi coi đã triển khai. Giấy phép/provenance vẫn dẫn tới tài liệu gốc.
