Đặc tả Yêu cầu Phần mềm (SRS) **EduNexus:** **Nền** **tảng** **Học**
**tập** **&** **Đào** **tạo** **Tích** **hợp** **AI**

**Trường** **thông** **tin** **Tên** **Dự** **án**

**Tài** **liệu** **V&S** **Tham** **chiếu** **Tài** **liệu** **RTW**
**Tham** **chiếu** **Phiên** **bản** **SRS**

**Ngày** **Tạo**

**Cập** **nhật** **Lần** **cuối**

**Tác** **giả**

**Giá** **trị**

EduNexus: Nền tảng Học tập & Đào tạo Tích hợp AI Vision & Scope Document
v2.0.0 EduNexus_RTW.xlsx

v2 01/06/2026 03/06/2026

KienNT

Lịch sử Thay đổi Tài liệu

**Version** v1

v2

**Ngày** 01/06/2026

03/06/2026

**Nội** **dung** **Thay** **đổi** **Tác** **giả** Khởi tạo SRS baseline.
KienNT

Đổi tên dự án thành “EduNexus: Nền tảng Học tập & KienNT Đào tạo Tích
hợp AI”. Cập nhật tham chiếu V&S sang

v2.

Bỏ khái niệm tầng trong Phần 0 và Phần 3 — chỉ giữ bảng FE→FT trong Phần
1.3. Cập nhật FT-14 (Xác thực & Hồ sơ Người dùng) và FT-15 (Quản trị Hệ
thống) theo điều chỉnh scope. Đổi tên FE-01 đến FE-05 đồng bộ với VS v2.

Phần 0 — Tổng quan Tài liệu

SRS này đặc tả yêu cầu chức năng và phi chức năng của EduNexus — nền
tảng học tập và đào tạo tích hợp AI, hoạt động hoàn toàn độc lập. Tài
liệu mô tả **15** **tính** **năng** **kỹ** **thuật** **(FT-01** **đến**
**FT-15)** ánh xạ từ 5 tính năng stakeholder (FE-01 đến FE-05) trong V&S
v2.0.0.

EduNexus không tích hợp với Google Classroom hay bất kỳ LMS bên ngoài
nào. Toàn bộ quản lý lớp học, học viên và điểm số đều thực hiện trong hệ
thống.

**Lưu** **ý:** Tính năng đăng ký tài khoản, đăng nhập và quản lý hồ sơ
cá nhân (FT-14) là tính năng nền tảng bắt buộc, là điều kiện tiên quyết
cho mọi tính năng khác trong hệ thống.

Phần 1 — Tổng quan Hệ thống 1.1 Phạm vi Tích hợp

**Chiều**

***Các*** ***tính*** ***năng*** ***chính***

***Kết*** ***nối*** ***đến*** ***bên*** ***ngoài***

***Nhận*** ***từ*** ***bên*** ***ngoài***

***Không*** ***tích*** ***hợp***

**Nội** **dung**

Quản lý cấu trúc khóa học; soạn thảo bài giảng & tài liệu; ngân hàng câu
hỏi; thẻ ghi nhớ; bài tập tự luận; học & luyện tập; đánh giá; quản lý
lớp học; thanh toán; báo cáo & phân tích; quản trị.

Google Identity (đăng nhập bằng Google); AI language model (hỗ trợ soạn
thảo & chấm điểm tự động); YouTube Data API (tóm tắt video); VNPay
(thanh toán); SePay (thanh toán).

Thông báo xác nhận thanh toán từ VNPay và SePay. Mọi kết nối khác đều do
EduNexus chủ động gọi ra.

Google Classroom và các LMS bên ngoài khác. Toàn bộ quản lý lớp học và
điểm số thực hiện trong EduNexus.

1.2 Vai trò Người dùng

**Vai** **trò** **Loại**

***Quản*** ***trị*** ***viên*** Nội bộ ***(Admin)***

***Chuyên*** ***gia*** Nội bộ ***Nội*** ***dung***

***(SME)***

***Giảng*** ***viên*** Nội bộ ***(Teacher)***

***Người*** ***quản*** Nội bộ ***lý*** ***Khóa*** ***học***

***(Course*** ***Manager)***

***Học*** ***viên*** Bên ***(Student)*** ngoài

***Khách*** ***(Guest)*** Bên ngoài

**Quyền** **hạn** **chính**

Quản lý tài khoản và phân quyền toàn hệ thống; tạo và cấu hình khóa học;
thiết lập nhóm khóa học và phân công Course Manager; xem báo cáo toàn hệ
thống; xử lý hoàn tiền; cấu hình hệ thống.

Toàn quyền soạn thảo nội dung trong khóa học được phân công: bài giảng,
video, tài liệu, câu hỏi, thẻ ghi nhớ, bài tập tự luận. Xuất bản và cập
nhật nội dung khóa học.

Bổ sung tài liệu riêng cho lớp học; chấm điểm và xác nhận kết quả bài
luận; theo dõi tiến độ học viên; giảng dạy lớp học.

Thiết lập giá, tạo lớp học, tạo gói đăng ký trong phạm vi nhóm khóa học
được phân công; theo dõi doanh thu và tình hình đăng ký.

Học bài giảng, ôn luyện flashcard, làm bài kiểm tra, nộp bài luận; đăng
ký và thanh toán khóa học; xem tiến độ học tập cá nhân.

Xem danh mục khóa học công khai; thử tối đa 10 câu hỏi và 5 thẻ ghi nhớ
mẫu; không truy cập nội dung đầy đủ và tính năng AI.

**Lưu** **ý** **về** **Course** **Manager:** Chỉ thao tác trong phạm vi
nhóm khóa học được Admin phân công. Xem chi tiết BR-13, BR-14, BR-15.

1.3 Bảng Ánh xạ Tính năng (FE → FT)

**FE** **Stakeholder** **FT** **ID**

***FE-01*** ***—*** ***Xây*** ***dựng*** ***&*** **FT-01** ***Quản***
***lý*** ***Nội*** ***dung*** ***Khóa***

***học***

> **FT-02** **FT-03** **FT-04** **FT-05**

***FE-02*** ***—*** ***Hỗ*** ***trợ*** ***Soạn*** ***thảo*** **FT-06**
***bằng*** ***AI***

> **FT-07** **FT-08**

***FE-03*** ***—*** ***Học*** ***tập*** ***&*** ***Luyện*** **FT-06**
***tập***

> **FT-07** **FT-08**

***FE-04*** ***—*** ***Theo*** ***dõi*** ***Tiến*** ***độ*** **FT-12**
***&*** ***Phân*** ***tích*** ***Kết*** ***quả***

> **FT-13**

***FE-05*** ***—*** ***Mở*** ***Lớp*** ***học*** ***&*** **FT-09**
***Quản*** ***lý*** ***Đăng*** ***ký***

> **FT-10** **FT-11**

***Nền*** ***tảng*** **FT-14**

> **FT-15**

**Tên** **Tính** **năng**

Quản lý cấu trúc khóa học

Soạn thảo bài giảng & tài liệu học tập

Xây dựng ngân hàng câu hỏi & bài kiểm tra Xây dựng bộ thẻ ghi nhớ
(Flashcard)

Tạo bài tập tự luận & tiêu chí chấm điểm Học bài giảng & ôn luyện thẻ
ghi nhớ

Làm bài kiểm tra & xem kết quả Nộp bài, chấm điểm & trả kết quả

Học bài giảng & ôn luyện thẻ ghi nhớ

Làm bài kiểm tra & xem kết quả Nộp bài, chấm điểm & trả kết quả Theo dõi
tiến độ học tập cá nhân

Phân tích kết quả lớp học & nội dung Quản lý lớp học

Quản lý danh mục & gói học phí Đăng ký & thanh toán khóa học Xác thực &
Hồ sơ Người dùng

Quản trị Hệ thống

Phần 2 — Luồng Nghiệp vụ (5 Kịch bản) SC-01 — Xây dựng & Xuất bản Nội
dung Khóa học

> • **Tác** **nhân** **Chính:** Admin → SME
>
> • **Điều** **kiện** **Bắt** **đầu:** Chưa có khóa học nào trong hệ
> thống hoặc cần cập nhật nội dung khóa học hiện có.
>
> • **Điều** **kiện** **Kết** **thúc:** Nội dung khóa học hoàn chỉnh,
> được xuất bản và sẵn sàng đưa vào sử dụng.
>
> • **FT** **Liên** **quan:** FT-01, FT-02, FT-03, FT-04, FT-05

**Mô** **tả:**

Admin khởi tạo khóa học trong hệ thống và chỉ định chuyên gia nội dung
phụ trách biên soạn.

Chuyên gia nội dung bắt đầu xây dựng chương trình học theo từng module
bài học. Với mỗi module, chuyên gia soạn bài giảng văn bản, nhúng video
YouTube kèm tóm tắt nội dung AI, đính kèm tài liệu đọc thêm. AI hỗ trợ
mở rộng đề cương thành bài giảng hoàn chỉnh — kết quả được chuyên gia
xem xét và chỉnh sửa trước khi sử dụng.

Song song đó, chuyên gia xây dựng tài nguyên luyện tập và đánh giá: nhập
câu hỏi trắc nghiệm vào ngân hàng câu hỏi bằng cách nhập tay, tải lên
file Excel hàng loạt hoặc nhờ AI gợi ý rồi phê duyệt từng câu; tương tự
với bộ thẻ ghi nhớ theo nhóm chủ đề; soạn bài tập tự luận với đề bài và
bộ tiêu chí chấm điểm rõ ràng.

Khi nội dung hoàn chỉnh, chuyên gia xuất bản khóa học. Nội dung gốc được
bảo vệ — giảng viên các lớp học chỉ được bổ sung tài liệu riêng cho lớp
mình, không thay đổi được nội dung gốc.

Khi cần cập nhật nội dung đã xuất bản (sửa bài giảng lỗi thời, bổ sung
câu hỏi mới, thay video cũ), chuyên gia mở khóa tạm thời, chỉnh sửa và
xuất bản lại. Hệ thống ghi nhận phiên bản thay đổi để theo dõi lịch sử.

SC-02 — Mở Lớp học & Thiết lập Điều kiện Tham gia • **Tác** **nhân**
**Chính:** Admin, Course Manager

> • **Điều** **kiện** **Bắt** **đầu:** Đã có ít nhất một khóa học được
> xuất bản.
>
> • **Điều** **kiện** **Kết** **thúc:** Lớp học sẵn sàng cho học viên
> đăng ký; điều kiện tham gia được thiết lập đầy đủ.
>
> • **FT** **Liên** **quan:** FT-09, FT-10

**Mô** **tả:**

Admin hoặc Course Manager tạo lớp học mới trên EduNexus: chọn khóa học
gốc, đặt tên lớp, ngày khai giảng, ngày kết thúc, sĩ số tối đa và chỉ
định giảng viên phụ trách. Lớp học có thể miễn phí (Admin thêm học viên
trực tiếp) hoặc có học phí (học viên tự đăng ký và thanh toán). Toàn bộ
danh sách học viên và sổ điểm được quản lý trong EduNexus.

Giảng viên được phân công có thể bổ sung thêm tài liệu riêng phù hợp với
nhóm lớp — video bổ sung, bài đọc thêm, flashcard riêng — mà không ảnh
hưởng đến nội dung gốc của chuyên gia biên soạn.

Song song đó, Course Manager thiết lập điều kiện tham gia vào nội dung
khóa học: đặt giá mua lẻ từng khóa học để học viên tự học không giới hạn
thời gian; tạo gói đăng ký theo thời hạn (1, 3, 6 tháng hoặc 1 năm) cho
phép truy cập toàn bộ khóa học trong một nhóm chủ đề. Admin thiết lập
cấu trúc nhóm khóa học và phân công Course Manager phụ trách từng nhóm.

SC-03 — Đăng ký & Ghi danh vào Khóa học • **Tác** **nhân** **Chính:**
Học viên

> • **Điều** **kiện** **Bắt** **đầu:** Có lớp học hoặc khóa học mở để
> đăng ký.
>
> • **Điều** **kiện** **Kết** **thúc:** Học viên có tài khoản và quyền
> truy cập vào khóa học đã chọn. • **FT** **Liên** **quan:** FT-11

**Mô** **tả:**

Người học truy cập EduNexus, tạo tài khoản bằng email hoặc đăng nhập
nhanh qua tài khoản Google. Sau khi đăng nhập, người học duyệt trang
danh mục khóa học công khai — có thể xem thử tối đa 10 câu hỏi và 5 thẻ
ghi nhớ mẫu trước khi quyết định.

Khi chọn được khóa học phù hợp, người học chọn hình thức tham gia:

> • **Mua** **lẻ** **một** **khóa** **học:** Trả một lần, học không giới
> hạn thời gian.
>
> • **Đăng** **ký** **lớp** **học** **có** **giảng** **viên:** Tham gia
> lớp học trong khoảng thời gian xác định, có tương tác với giảng viên.
>
> • **Mua** **gói** **đăng** **ký** **theo** **thời** **hạn:** Truy cập
> toàn bộ khóa học trong một nhóm chủ đề.

Người học thanh toán qua VNPay hoặc SePay. Quyền truy cập được cấp tự
động sau khi thanh toán thành công — học viên vào học ngay lập tức. Với
lớp học miễn phí do Admin mời, học viên nhận email thông báo và truy cập
trực tiếp không cần thanh toán.

SC-04 — Học, Luyện tập & Đánh giá • **Tác** **nhân** **Chính:** Học
viên, Teacher

> • **Điều** **kiện** **Bắt** **đầu:** Học viên đã có quyền truy cập vào
> khóa học.
>
> • **Điều** **kiện** **Kết** **thúc:** Học viên hoàn thành nội dung,
> bài kiểm tra và bài tập; kết quả được ghi nhận.
>
> • **FT** **Liên** **quan:** FT-06, FT-07, FT-08, FT-12

**Mô** **tả:**

Học viên vào trang học của module: đọc bài giảng văn bản, xem video bài
học kèm tóm tắt nội dung chính bên dưới, tải tài liệu đính kèm. Đánh dấu
hoàn thành từng bài — tiến độ cập nhật trên thanh tiến trình module.

Sau phần học lý thuyết, học viên chuyển sang ôn luyện trong cùng không
gian: lật thẻ ghi nhớ theo nhóm chủ đề — thẻ chưa thuộc được ưu tiên lặp
lại nhiều hơn; hoặc tự tạo bài kiểm tra thực hành từ ngân hàng câu hỏi
với tham số tùy chọn, làm bài và xem ngay kết quả

chi tiết từng câu. Kết quả luyện tập chỉ dùng để tự đánh giá, không tính
vào điểm chính thức.

Với bài tập tự luận, học viên đọc đề bài và tiêu chí chấm điểm, soạn bài
và nộp. Hệ thống tự động chấm sơ bộ theo từng tiêu chí ngay sau khi nộp.
Giảng viên xem bài nộp cùng kết quả chấm sơ bộ của hệ thống, điều chỉnh
nếu cần và xác nhận điểm cuối cùng. Học viên nhận thông báo và xem điểm
kèm nhận xét của giảng viên.

Học viên có thể xem tổng quan tiến độ học tập cá nhân bất kỳ lúc nào:
bài nào đã học, module nào đang học dở, điểm bài kiểm tra theo thời
gian, tỷ lệ đúng theo chủ đề, thẻ ghi nhớ đã thuộc bao nhiêu.

SC-05 — Vận hành & Theo dõi Lớp học

> • **Tác** **nhân** **Chính:** Teacher, Course Manager, Admin
>
> • **Điều** **kiện** **Bắt** **đầu:** Lớp học đã khai giảng và đang
> hoạt động.
>
> • **Điều** **kiện** **Kết** **thúc:** Lớp học vận hành trơn tru; các
> vấn đề phát sinh được xử lý kịp thời.
>
> • **FT** **Liên** **quan:** FT-09, FT-10, FT-11, FT-13, FT-14, FT-15

**Mô** **tả:**

**Giảng** **viên** theo dõi tổng quan tiến độ cả lớp hàng ngày: xem học
viên nào chưa vào học, ai đang học chậm hơn so với tiến độ chung, module
nào nhiều người bỏ dở nhất. Xem danh sách bài luận đang chờ chấm và xử
lý theo đợt. Khi cần, gửi thông báo nhắc nhở học viên chưa vào học hoặc
sắp đến hạn nộp bài.

**Course** **Manager** theo dõi tình hình đăng ký và doanh thu theo thời
gian thực: số học viên mới đăng ký từng ngày, doanh thu theo lớp và theo
gói đăng ký, so sánh với các kỳ trước. Khi cần, điều chỉnh sĩ số tối đa
hoặc gia hạn thời gian lớp học. Tiếp nhận và xử lý yêu cầu hoàn tiền từ
học viên — xác minh lý do, thu hồi quyền truy cập và kích hoạt hoàn tiền
qua cổng thanh toán.

**Admin** xem báo cáo tổng quan toàn hệ thống: doanh thu tổng hợp, số
lượng học viên đang hoạt động, tình trạng các lớp học, các tài khoản
mới. Xử lý các vấn đề leo thang từ Course Manager hoặc Teacher. Điều
chỉnh cấu hình hệ thống khi cần (giới hạn file, hạn mức AI, thông số
cổng thanh toán).

Phần 3 — Mô tả Tính năng FT-01 — Quản lý Cấu trúc Khóa học

> • **Nguồn** **V&S:** FE-01 \| **Luồng:** SC-01, SC-02

**Mô** **tả** **chức** **năng:** Admin khởi tạo khóa học và chỉ định
chuyên gia nội dung phụ trách. Chuyên gia xây dựng cấu trúc module bài
học. Khi hoàn chỉnh, chuyên gia xuất bản khóa học — nội dung gốc được
bảo vệ, giảng viên các lớp chỉ được bổ sung tài liệu riêng cho lớp mình.
Lớp học tự động kế thừa toàn bộ nội dung từ khóa học gốc. Khi cần cập
nhật, chuyên gia mở khóa, chỉnh sửa và xuất bản lại.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-01a:** Toàn bộ nội dung khóa học gốc hiển thị đầy đủ trong lớp
học trong vòng 2 giây. - **AC-01b:** Tài liệu bổ sung của giảng viên lưu
riêng biệt, không ảnh hưởng nội dung gốc.

\- **AC-01c:** Khóa học phải có ít nhất 1 module bài học trước khi được
xuất bản. - **AC-01d:** Hệ thống lưu lịch sử các lần chỉnh sửa và xuất
bản lại nội dung.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-01-a:** Giảng viên cố sửa hoặc xóa nội dung gốc phải bị từ chối
và thông báo lỗi rõ ràng. - **NAC-01-b:** Giảng viên lớp A không được
xem hay truy cập tài liệu của lớp B.

FT-02 — Soạn thảo Bài giảng & Tài liệu Học tập • **Nguồn** **V&S:**
FE-01, FE-02 \| **Luồng:** SC-01, SC-02

**Mô** **tả** **chức** **năng:** Chuyên gia nội dung và giảng viên soạn
thảo nội dung bài học trong một giao diện biên soạn thống nhất theo
module với ba loại nội dung:

**Bài** **giảng** **văn** **bản:** Soạn thảo Markdown với đầy đủ định
dạng. Bản xem trước hiển thị ngay khi soạn. AI hỗ trợ mở rộng đề cương
thành bài giảng hoàn chỉnh — chuyên gia xem, chỉnh sửa và chèn vào bài
nếu hài lòng.

**Video** **YouTube:** Nhập đường dẫn YouTube, hệ thống xác minh và
nhúng vào bài học. Có thể kích hoạt AI tóm tắt nội dung video — hệ thống
phân tích phụ đề và tạo ghi chú học tập có cấu trúc hiển thị bên dưới
video.

**Tệp** **tài** **liệu:** Tải lên PDF, Word, ZIP làm tài liệu đọc thêm.
Học viên tải xuống trực tiếp từ bài học.

Chuyên gia sắp xếp thứ tự nội dung bằng kéo thả. Giảng viên chỉ được bổ
sung nội dung riêng cho lớp, không sửa nội dung gốc.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-02a:** Bản xem trước bài giảng cập nhật trong vòng 200ms khi
soạn thảo. - **AC-02b:** Xác minh đường dẫn YouTube hoàn thành trong
vòng 3 giây.

\- **AC-02c:** Video hiển thị đúng tỷ lệ 16:9 trên mọi kích thước màn
hình. - **AC-02d:** Bài giảng hỗ trợ tối thiểu 50.000 ký tự.

\- **AC-02e:** Thứ tự sắp xếp nội dung được lưu ngay sau khi kéo thả.

\- **AC-02f:** AI tóm tắt video hoàn thành trong vòng 4 giây; ưu tiên
tiếng Việt nếu video có phụ đề tiếng Việt.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-02-a:** Nội dung văn bản rỗng không được lưu.

\- **NAC-02-b:** Giảng viên sửa hoặc xóa nội dung gốc phải bị từ chối.

\- **NAC-02-c:** Tệp vượt giới hạn kích thước (CFG-B01) phải bị từ chối,
không lưu lên hệ thống. - **NAC-02-d:** Đường dẫn YouTube không hợp lệ
hoặc video không tồn tại phải hiển thị thông báo lỗi rõ ràng.

\- **NAC-02-e:** Chỉ chấp nhận video từ YouTube; từ chối đường dẫn từ
nền tảng khác.

\- **NAC-02-f:** Video không có phụ đề phải thông báo tính năng tóm tắt
không khả dụng thay vì báo lỗi hệ thống.

FT-03 — Xây dựng Ngân hàng Câu hỏi & Bài kiểm tra • **Nguồn** **V&S:**
FE-01, FE-02, FE-03 \| **Luồng:** SC-01

**Mô** **tả** **chức** **năng:** Chuyên gia xây dựng ngân hàng câu hỏi
trắc nghiệm theo ba cách:

**Nhập** **thủ** **công:** Soạn từng câu với nội dung, 2–6 đáp án, đáp
án đúng, giải thích (tùy chọn), độ khó và module tương ứng. Câu hỏi vào
ngân hàng sử dụng ngay.

**Nhập** **hàng** **loạt** **từ** **file** **Excel:** Tải lên theo mẫu
chuẩn. Từng dòng xử lý độc lập — dòng hợp lệ nhập vào ngân hàng, dòng
lỗi liệt kê chi tiết trong báo cáo. Không dừng toàn bộ khi có một vài
dòng lỗi.

**AI** **gợi** **ý** **câu** **hỏi:** Chọn văn bản nguồn, AI tạo câu hỏi
vào khu vực chờ duyệt riêng — chuyên gia xem xét từng câu, chỉnh sửa và
phê duyệt đưa vào ngân hàng. AI không tự động đưa câu hỏi vào ngân hàng
khi chưa qua kiểm duyệt.

Chuyên gia xem toàn bộ ngân hàng với bộ lọc theo module, độ khó, trạng
thái; tìm kiếm theo nội dung; xóa câu hỏi không dùng.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-03a:** Câu hỏi thủ công phải có ít nhất 2 đáp án và đúng 1 đáp
án đúng.

\- **AC-03b:** Import Excel: báo cáo rõ số dòng thành công, lỗi và lý do
lỗi từng dòng. - **AC-03c:** Phê duyệt câu hỏi từ khu vực chờ vào ngân
hàng thực hiện tức thì.

\- **AC-03d:** Hỗ trợ lọc theo module, độ khó, trạng thái và tìm kiếm
nội dung.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-03-a:** Học viên không xem được ngân hàng câu hỏi ngoài lúc
đang làm bài kiểm tra. - **NAC-03-b:** Giảng viên không tạo hoặc sửa câu
hỏi trong ngân hàng gốc của khóa học.

\- **NAC-03-c:** File Excel thiếu cột bắt buộc phải bị từ chối toàn bộ
với thông báo lỗi cụ thể.

\- **NAC-03-d:** AI không tự động đưa câu hỏi vào ngân hàng khi chưa có
phê duyệt của chuyên gia.

FT-04 — Xây dựng Bộ thẻ Ghi nhớ (Flashcard) • **Nguồn** **V&S:** FE-01,
FE-02, FE-03 \| **Luồng:** SC-01, SC-02

**Mô** **tả** **chức** **năng:** Chuyên gia và giảng viên tạo bộ thẻ ghi
nhớ theo nhóm chủ đề trong module. Mỗi thẻ gồm mặt trước (thuật ngữ) và
mặt sau (định nghĩa).

**Nhập** **thủ** **công:** Tạo từng thẻ, đặt tên nhóm, sắp xếp thứ tự,
di chuyển thẻ giữa các nhóm.

**Nhập** **hàng** **loạt** **từ** **file** **CSV:** Tải lên file 2 cột
(thuật ngữ, định nghĩa). Có thể thêm cột tên nhóm để tự phân loại. Xử lý
từng dòng độc lập, báo cáo lỗi chi tiết.

**AI** **gợi** **ý** **thẻ:** Chọn văn bản nguồn, AI tạo cặp thuật
ngữ–định nghĩa vào khu vực chờ duyệt. Chuyên gia xem xét và phê duyệt
đưa vào nhóm chỉ định.

Khi xóa một nhóm thẻ, người dùng chọn: xóa cả nhóm và thẻ bên trong,
hoặc chỉ xóa nhóm và giữ lại thẻ vào mục “Chưa phân nhóm”. Giảng viên
chỉ được thêm thẻ riêng cho lớp, không sửa thẻ gốc.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-04a:** Mỗi module tối đa 200 thẻ tổng cộng (CR-06).

\- **AC-04b:** Nội dung mỗi mặt thẻ không rỗng; tối đa 500 ký tự mỗi
mặt. - **AC-04c:** Import CSV: báo lỗi từng dòng, nhập các dòng hợp lệ.

\- **AC-04d:** Di chuyển thẻ sang nhóm khác không làm mất dữ liệu.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-04-a:** Xóa nhóm thẻ khi học viên có tiến độ học liên kết phải
cảnh báo tiến độ sẽ bị mất.

\- **NAC-04-b:** Giảng viên sửa hoặc xóa thẻ gốc của chuyên gia phải bị
từ chối.

\- **NAC-04-c:** File CSV thiếu cột bắt buộc phải bị từ chối với thông
báo lỗi cụ thể.

FT-05 — Tạo Bài tập Tự luận & Tiêu chí Chấm điểm • **Nguồn** **V&S:**
FE-01, FE-02 \| **Luồng:** SC-01, SC-04

**Mô** **tả** **chức** **năng:** Giảng viên và chuyên gia soạn bài tập
tự luận gồm đề bài (Markdown), hạn nộp bài và bộ tiêu chí chấm điểm
(rubric). Mỗi tiêu chí có tên gọi, tỷ trọng (%) và điểm tối đa. Hệ thống
cảnh báo thời gian thực khi tổng tỷ trọng chưa đúng 100% — chỉ cho phép
đăng bài tập khi đủ và có ít nhất một tiêu chí. Sau khi có học viên nộp
bài, tiêu chí bị khóa; chỉ được gia hạn thêm ngày nộp.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-05a:** Cảnh báo tức thì khi tổng tỷ trọng chưa đủ 100%.

\- **AC-05b:** Không thể đăng bài tập khi chưa có tiêu chí hoặc tổng tỷ
trọng sai. - **AC-05c:** Học viên thấy đầy đủ đề bài, tiêu chí và tỷ
trọng khi mở bài tập.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-05-a:** Không thể sửa tiêu chí sau khi đã có học viên nộp
bài. - **NAC-05-b:** Tỷ trọng của một tiêu chí không được bằng 0 hoặc
âm.

\- **NAC-05-c:** Học viên không được truy cập màn hình tạo hoặc sửa bài
tập.

FT-06 — Học Bài giảng & Ôn luyện Thẻ Ghi nhớ • **Nguồn** **V&S:** FE-03
\| **Luồng:** SC-04

> • **Gộp** **từ:** FT-06 + FT-07 (v2.3.0)

**Mô** **tả** **chức** **năng:** Học viên truy cập bài học trong module.
Trang học hiển thị tất cả nội dung theo thứ tự: bài giảng văn bản, video
YouTube với tóm tắt nội dung bên dưới (nếu có), và tệp tài liệu có thể
tải xuống. Đánh dấu hoàn thành từng bài — tiến độ cập nhật trên thanh
tiến trình module.

Sau phần học lý thuyết, học viên chuyển sang lật thẻ ghi nhớ trong cùng
module: chọn nhóm thẻ hoặc học toàn bộ thẻ của module. Nhấp/chạm để lật
thẻ xem mặt sau. Đánh dấu “Đã thuộc” hoặc “Chưa thuộc” — thẻ chưa thuộc
được ưu tiên lặp lại nhiều hơn. Tiến độ học thẻ được lưu sau mỗi phiên.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-06a:** Trang bài học tải đầy đủ trong vòng 1 giây.

\- **AC-06b:** Tiến độ hoàn thành bài học ghi nhận trong vòng 500ms.

\- **AC-06c:** Hiệu ứng lật thẻ mượt mà trên cả màn hình cảm ứng và
thiết bị dùng chuột. - **AC-06d:** Tiến độ học thẻ lưu trong vòng 500ms
sau khi hoàn thành phiên.

\- **AC-06e:** Học viên chọn học từng nhóm thẻ riêng hoặc toàn bộ thẻ
của module.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-06-a:** Học viên không có quyền truy cập không được xem nội
dung bài học.

\- **NAC-06-b:** Module chưa có nội dung hiển thị thông báo thân thiện
thay vì trang trắng.

\- **NAC-06-c:** Nhóm thẻ không có thẻ nào hiển thị thông báo thân thiện
thay vì lỗi hệ thống.

FT-07 — Làm Bài kiểm tra & Xem Kết quả • **Nguồn** **V&S:** FE-03 \|
**Luồng:** SC-04

> • **Đổi** **số** **từ:** FT-08 (v2.3.0) → FT-07

**Mô** **tả** **chức** **năng:** Học viên tự tạo bài kiểm tra thực hành
bằng cách chọn phạm vi (module nào), số lượng câu hỏi và độ khó. Hệ
thống rút ngẫu nhiên câu hỏi phù hợp. Học viên làm bài, chọn đáp án và
nộp. Màn hình kết quả hiển thị điểm tổng, từng câu đúng/sai, đáp án đúng
và giải thích. Kết quả chỉ dùng để tự đánh giá, không tính vào điểm
chính thức.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-07a:** Bài kiểm tra được tạo trong vòng 1,5 giây.

\- **AC-07b:** Kết quả hiển thị đầy đủ: điểm tổng, từng câu đúng/sai,
đáp án đúng và giải thích. - **AC-07c:** Điểm luyện tập hoàn toàn tách
biệt khỏi sổ điểm chính thức.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-07-a:** Nếu câu hỏi có sẵn ít hơn yêu cầu, hệ thống lấy tất cả
câu có sẵn thay vì báo lỗi. - **NAC-07-b:** Học viên không xem được đáp
án câu hỏi ngoài ngữ cảnh bài kiểm tra đang làm.

FT-08 — Nộp Bài, Chấm điểm & Trả Kết quả •     **Nguồn** **V&S:** FE-02,
FE-03 \| **Luồng:** SC-04, SC-05

> • **Gộp** **từ:** FT-09 + FT-10 (v2.3.0) → FT-08

**Mô** **tả** **chức** **năng:** Tính năng này bao trùm toàn bộ vòng đời
bài tập tự luận — từ khi học viên nộp bài đến khi nhận kết quả:

**Phía** **học** **viên:** Mở bài tập, đọc đề bài và tiêu chí chấm điểm
kèm tỷ trọng. Đồng hồ đếm ngược đến hạn nộp hiển thị rõ ràng. Soạn bài
trong trình soạn thảo tích hợp (tối đa 20.000 ký tự) và nộp bài — sau
khi nộp, bài không thể chỉnh sửa. Mỗi học viên chỉ được nộp một lần. Sau
khi giảng viên xác nhận, học viên nhận thông báo và xem điểm kèm nhận
xét.

**Phía** **hệ** **thống:** Ngay sau khi học viên nộp bài, hệ thống tự
động chấm sơ bộ theo từng tiêu chí trong rubric và đưa ra điểm gợi ý kèm
nhận xét. Kết quả này chỉ hiển thị cho giảng viên.

**Phía** **giảng** **viên:** Xem danh sách bài nộp của lớp. Mở từng bài,
đọc bài làm cùng kết quả chấm sơ bộ của hệ thống. Điều chỉnh điểm từng
tiêu chí nếu cần, viết nhận xét tổng thể và xác nhận điểm cuối cùng.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-08a:** Học viên thấy đề bài, tiêu chí, tỷ trọng và đồng hồ đếm
ngược khi mở bài tập. - **AC-08b:** Khi hết hạn nộp, nút “Nộp bài” bị vô
hiệu hoá tự động.

\- **AC-08c:** Kết quả chấm sơ bộ hiển thị trong giao diện chấm điểm của
GV trong vòng 5 giây. - **AC-08d:** Học viên nhận thông báo ngay sau khi
giảng viên xác nhận điểm.

\- **AC-08e:** Học viên xem điểm từng tiêu chí và nhận xét sau khi giảng
viên xác nhận.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-08-a:** Nộp bài sau hạn phải bị từ chối với thông báo rõ
ràng. - **NAC-08-b:** Nộp bài lần 2 phải bị từ chối.

\- **NAC-08-c:** Học viên không xem được kết quả chấm sơ bộ trước khi
giảng viên xác nhận. - **NAC-08-d:** Bài nộp rỗng phải bị từ chối.

\- **NAC-08-e:** Điểm cuối cùng bắt buộc phải có xác nhận thủ công của
giảng viên — hệ thống không tự động ghi điểm.

FT-09 — Quản lý Lớp học

> • **Nguồn** **V&S:** FE-05 \| **Luồng:** SC-02, SC-05

**Mô** **tả** **chức** **năng:** Admin hoặc Course Manager tạo và quản
lý lớp học thống nhất trên EduNexus — không phân biệt lớp miễn phí hay
có học phí, tất cả đều được tạo và quản lý theo cùng một quy trình.

**Tạo** **lớp** **học:** Chọn khóa học gốc, đặt tên lớp, ngày khai
giảng, ngày kết thúc, sĩ số tối đa, học phí (0 = miễn phí) và chỉ định
giảng viên. Lớp miễn phí: Admin thêm học viên trực tiếp bằng email hoặc
gửi đường dẫn mời. Lớp có học phí: hiển thị trên danh mục để học viên tự
đăng ký và thanh toán.

**Quản** **lý** **sau** **khai** **giảng:** Xem danh sách học viên đã
đăng ký cùng trạng thái thanh toán và tiến độ học. Điều chỉnh sĩ số hoặc
gia hạn lớp học khi cần. Xóa học viên khỏi lớp nếu cần thiết (ghi log lý
do). Gửi thông báo đến toàn bộ học viên trong lớp.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-09a:** Course Manager chỉ tạo và quản lý lớp trong phạm vi nhóm
khóa học được phân công.

\- **AC-09b:** Khi lớp đến ngày kết thúc, quyền truy cập của học viên
được thu hồi tự động trong vòng 1 giờ.

\- **AC-09c:** Danh sách học viên hiển thị đầy đủ trạng thái thanh toán
và tiến độ học.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-09-a:** Khi lớp đủ sĩ số, không nhận thêm đăng ký mới và hiển
thị thông báo hết chỗ.

\- **NAC-09-b:** Course Manager không thao tác trên nhóm khóa học ngoài
phạm vi được phân công.

FT-10 — Quản lý Danh mục & Gói Học phí • **Nguồn** **V&S:** FE-05 \|
**Luồng:** SC-02, SC-05

> • **Đổi** **số** **từ:** FT-12 (v2.3.0) → FT-10

**Mô** **tả** **chức** **năng:**

**Admin:** Tạo nhóm khóa học (gom các khóa học liên quan theo chủ đề),
chỉ định Course Manager phụ trách. Xem báo cáo doanh thu tổng hợp toàn
hệ thống.

**Course** **Manager:** Trong phạm vi nhóm được phân công, đặt giá mua
lẻ từng khóa học (H1 — học vĩnh viễn); tạo gói đăng ký theo thời hạn 1,
3, 6 tháng hoặc 1 năm cho toàn bộ khóa học trong nhóm (H3). Bật/tắt hiển
thị từng khóa học trên danh mục. Xem báo cáo doanh thu trong phạm vi
được giao.

Khi học viên gia hạn gói còn hiệu lực, thời gian được cộng dồn thêm vào.
Khóa học mới thêm vào nhóm sau khi học viên đã mua gói cũng được truy
cập ngay.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-10a:** Học viên mua gói truy cập tất cả khóa học trong nhóm, kể
cả khóa học thêm vào sau ngày mua.

\- **AC-10b:** Gia hạn gói còn hiệu lực được cộng dồn chính xác.

\- **AC-10c:** Quyền mua lẻ (H1) không bị ảnh hưởng khi gói (H3) hết
hạn.

\- **AC-10d:** Danh mục công khai cập nhật giá và trạng thái trong vòng
1 giây.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-10-a:** Admin không thể xóa nhóm khi có học viên với gói đăng
ký còn hiệu lực.

\- **NAC-10-b:** Course Manager không tạo gói cho nhóm ngoài phạm vi
được phân công.

FT-11 — Đăng ký & Thanh toán Khóa học • **Nguồn** **V&S:** FE-05 \|
**Luồng:** SC-03, SC-05

> • **Thay** **đổi:** Thay MoMo → SePay

**Mô** **tả** **chức** **năng:** Học viên chọn hình thức tham gia và
thanh toán qua VNPay hoặc SePay. Ngay sau khi xác nhận thanh toán thành
công, hệ thống tự động cấp quyền truy cập:

> • **Mua** **lẻ** **khóa** **học** **(H1):** Quyền truy cập vĩnh viễn.
>
> • **Đăng** **ký** **lớp** **học** **có** **giảng** **viên** **(H2):**
> Quyền truy cập trong thời gian lớp diễn ra.
>
> • **Mua** **gói** **đăng** **ký** **(H3):** Quyền truy cập toàn bộ
> khóa học trong nhóm theo thời hạn.

Khi quyền truy cập hết hạn, tự động thu hồi nhưng giữ nguyên toàn bộ
lịch sử học. Nếu cần hoàn tiền, Admin xử lý thủ công và thu hồi quyền
truy cập trước khi thực hiện hoàn tiền.

SePay hỗ trợ đa phương thức trong một tích hợp: chuyển khoản ngân hàng,
QR code, thẻ ATM nội địa và thẻ quốc tế — học viên có nhiều lựa chọn hơn
khi thanh toán.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-11a:** Quyền truy cập được cấp trong vòng 5 giây sau khi nhận
xác nhận thanh toán.

\- **AC-11b:** Gói đăng ký hết hạn được thu hồi tự động trong vòng 15
phút sau thời điểm hết

hạn.

\- **AC-11c:** Mỗi lần thanh toán chỉ cấp quyền một lần dù nhận được
thông báo trùng lặp. - **AC-11d:** Lịch sử giao dịch thanh toán lưu đầy
đủ cho học viên và Admin xem lại.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-11-a:** Thanh toán thất bại không được cấp bất kỳ quyền truy
cập nào.

\- **NAC-11-b:** Học viên không có quyền hợp lệ không được xem nội dung
khóa học.

\- **NAC-11-c:** Thông báo xác nhận thanh toán không hợp lệ (sai chữ ký)
phải bị từ chối hoàn toàn.

FT-12 — Theo dõi Tiến độ Học tập Cá nhân • **Nguồn** **V&S:** FE-03 \|
**Luồng:** SC-04

> • **Mới** **hoàn** **toàn** **—** **v2.4.0**

**Mô** **tả** **chức** **năng:** Học viên xem tổng quan tiến độ học tập
của bản thân qua bảng điều khiển cá nhân, giúp biết mình đang ở đâu và
cần tập trung vào đâu:

**Tiến** **độ** **theo** **khóa** **học:** Tỷ lệ phần trăm bài học đã
hoàn thành theo từng module; thời gian học ước tính còn lại; ngày học
gần nhất.

**Kết** **quả** **bài** **kiểm** **tra:** Điểm theo thời gian (biểu đồ
xu hướng); tỷ lệ đúng phân tích theo chủ đề/module để học viên biết phần
nào đang yếu; so sánh lần kiểm tra gần nhất với trung bình các lần
trước.

**Tiến** **độ** **thẻ** **ghi** **nhớ:** Số thẻ đã thuộc / tổng thẻ theo
từng nhóm; danh sách thẻ cần ôn lại.

**Bài** **tập** **tự** **luận:** Danh sách bài đã nộp, trạng thái (chờ
chấm / đã chấm), điểm và nhận xét của giảng viên.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-12a:** Bảng tiến độ tải trong vòng 1,5 giây.

\- **AC-12b:** Dữ liệu tiến độ cập nhật ngay sau mỗi lần học viên hoàn
thành bài học, phiên flashcard hoặc bài kiểm tra.

\- **AC-12c:** Biểu đồ xu hướng điểm hiển thị tối thiểu 5 lần kiểm tra
gần nhất.

\- **AC-12d:** Học viên chỉ xem được dữ liệu của bản thân, không xem
được của học viên khác.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-12-a:** Dữ liệu luyện tập không làm sai lệch chỉ số tiến độ
chính thức.

FT-13 — Phân tích Kết quả Lớp học & Nội dung • **Nguồn** **V&S:** FE-02,
FE-05 \| **Luồng:** SC-05

> • **Mới** **hoàn** **toàn** **—** **v2.4.0**

**Mô** **tả** **chức** **năng:** Cung cấp dữ liệu phân tích cho giảng
viên, chuyên gia nội dung và Course Manager để cải thiện chất lượng dạy
và học:

**Dành** **cho** **Giảng** **viên** **—** **Tổng** **quan** **lớp**
**học:**

\- Bao nhiêu học viên đã vào học / chưa vào học trong 7 ngày qua.

\- Module nào có tỷ lệ hoàn thành thấp nhất — cần nhắc nhở học viên.

\- Câu hỏi nào trong bài kiểm tra có tỷ lệ sai cao nhất — có thể cần
giải thích thêm. - Điểm trung bình và phân phối điểm của cả lớp theo
từng bài kiểm tra và bài luận. - Danh sách học viên có nguy cơ bỏ học
(không hoạt động quá 7 ngày).

**Dành** **cho** **Chuyên** **gia** **Nội** **dung** **—** **Chất**
**lượng** **nội** **dung:**

\- Câu hỏi nào quá dễ (tỷ lệ đúng \> 90%) hoặc quá khó (tỷ lệ đúng \<
30%) — cần điều chỉnh. - Bài giảng nào có ít học viên đọc nhất — có thể
cần cải thiện tiêu đề hoặc nội dung.

\- Thẻ ghi nhớ nào bị đánh dấu “Chưa thuộc” nhiều nhất — có thể cần giải
thích rõ hơn.

**Dành** **cho** **Course** **Manager** **—** **Hiệu** **suất** **kinh**
**doanh:**

\- Doanh thu theo ngày/tuần/tháng; phân tích theo hình thức (mua lẻ /
gói đăng ký / lớp học). - Tỷ lệ hoàn thành khóa học — học viên mua xong
có học không.

\- Tỷ lệ gia hạn gói đăng ký.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-13a:** Báo cáo lớp học tải trong vòng 2 giây.

\- **AC-13b:** Dữ liệu phân tích cập nhật tối thiểu mỗi giờ một lần.

\- **AC-13c:** Giảng viên chỉ xem dữ liệu lớp học mình phụ trách; Course
Manager chỉ xem trong phạm vi nhóm được phân công; Admin xem toàn hệ
thống.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-13-a:** Dữ liệu cá nhân của từng học viên không được hiển thị
chi tiết cho Course Manager — chỉ hiển thị số liệu tổng hợp.

FT-14 — Xác thực & Hồ sơ Người dùng

> • **Nguồn** **V&S:** Nền tảng \| **Luồng:** SC-03, SC-04, SC-05
>
> • **Cập** **nhật** **v2.4.0:** Đổi tên và mở rộng scope — bao gồm toàn
> bộ luồng xác thực và quản lý hồ sơ cá nhân cho mọi vai trò người dùng.

**Mô** **tả** **chức** **năng:** Tính năng này phục vụ toàn bộ vòng đời
tài khoản từ góc nhìn người dùng — từ khi tạo tài khoản, đăng nhập hàng
ngày cho đến quản lý thông tin cá nhân. Hỗ trợ hai phương thức đăng ký
và đăng nhập song song.

**Đăng** **ký** **tài** **khoản:**

> • *Bằng* *email/password:* Người dùng nhập email, mật khẩu (tối thiểu
> 8 ký tự, có chữ, số và ký tự đặc biệt) và tên hiển thị. Hệ thống kiểm
> tra email chưa tồn tại và gửi email xác minh. Tài khoản chỉ được kích
> hoạt sau khi xác minh email thành công.
>
> • *Bằng* *Google:* Người dùng nhấn “Đăng ký bằng Google”, xác thực qua
> Google OAuth. Hệ thống tự động tạo tài khoản từ thông tin Google —
> không cần nhập mật khẩu. Nếu email Google đã tồn tại trong hệ thống,
> tự động liên kết với tài khoản hiện có.

**Đăng** **nhập:**

> • *Bằng* *email/password:* Nhập email và mật khẩu. Hệ thống xác thực
> và tạo phiên đăng nhập.
>
> • *Bằng* *Google:* Nhấn “Đăng nhập bằng Google”, chọn tài khoản
> Google, hệ thống xác thực qua OAuth và tạo phiên đăng nhập ngay lập
> tức.

**Quên** **&** **đổi** **mật** **khẩu:**

> • *Quên* *mật* *khẩu:* Nhập email, hệ thống gửi đường dẫn đặt lại có
> hiệu lực 1 giờ. Sau khi đặt lại thành công, tất cả phiên đăng nhập
> hiện tại bị đăng xuất.
>
> • *Đổi* *mật* *khẩu:* Người dùng đã đăng nhập nhập mật khẩu cũ và mật
> khẩu mới. Sau khi đổi thành công, tất cả phiên khác bị đăng xuất.

**Hồ** **sơ** **cá** **nhân:** Xem và cập nhật tên hiển thị, ảnh đại
diện (tối đa 2MB). Xem danh sách khóa học đang có quyền truy cập, gói
đăng ký đang hoạt động và ngày hết hạn, lịch sử giao dịch thanh toán.
Xem và quản lý các phiên đăng nhập đang hoạt động — đăng xuất từ xa từng
phiên hoặc tất cả cùng lúc.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-14a:** Email xác minh gửi trong vòng 60 giây sau khi đăng ký
bằng email.

\- **AC-14b:** Đăng nhập bằng Google hoàn tất trong vòng 3 giây sau khi
người dùng chọn tài khoản Google.

\- **AC-14c:** Đường dẫn đặt lại mật khẩu hết hiệu lực sau 1 giờ hoặc
sau lần sử dụng đầu tiên. - **AC-14d:** Đổi mật khẩu thành công đăng
xuất tất cả phiên khác trong vòng 5 giây.

\- **AC-14e:** Trang hồ sơ hiển thị đầy đủ khóa học đang sở hữu, gói
đăng ký và lịch sử giao dịch. - **AC-14f:** Đăng ký bằng Google với
email đã tồn tại trong hệ thống tự động liên kết tài khoản, không tạo
tài khoản mới.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-14-a:** Email đã tồn tại không được đăng ký thêm bằng
email/password — phải thông báo rõ ràng và gợi ý đăng nhập hoặc dùng
Google.

\- **NAC-14-b:** Mật khẩu không đủ yêu cầu phải bị từ chối với hướng dẫn
cụ thể.

\- **NAC-14-c:** Tài khoản đăng nhập bằng Google không có mật khẩu nội
bộ — không hiển thị tùy chọn đổi mật khẩu cho loại tài khoản này.

\- **NAC-14-d:** Đường dẫn đặt lại mật khẩu đã dùng hoặc hết hạn phải
hiển thị thông báo rõ ràng, không cho phép sử dụng lại.

\- **NAC-14-e:** Ảnh đại diện vượt 2MB phải bị từ chối với thông báo
giới hạn kích thước.

FT-15 — Quản trị Hệ thống

> • **Nguồn** **V&S:** Nền tảng \| **Luồng:** SC-05
>
> • **Cập** **nhật** **v2.4.0:** Mở rộng scope — bao gồm quản lý tài
> khoản nội bộ (SME, Teacher, Manager) gộp từ FT-14 cũ, kết hợp cấu hình
> và vận hành hệ thống.

**Mô** **tả** **chức** **năng:** Admin quản lý toàn bộ hoạt động vận
hành hệ thống qua bảng điều khiển quản trị tập trung:

**Quản** **lý** **tài** **khoản** **nội** **bộ:** Tạo tài khoản cho SME,
Teacher và Course Manager — các vai trò nội bộ không tự đăng ký được qua
FT-14. Nhập thông tin cơ bản, hệ thống gửi email mời và

hướng dẫn đặt mật khẩu lần đầu. Gán và thay đổi vai trò cho từng tài
khoản. Phân công Course Manager vào nhóm khóa học, phân công SME vào
khóa học cụ thể. Xem danh sách toàn bộ người dùng với bộ lọc theo vai
trò, trạng thái, ngày tạo. Kích hoạt hoặc vô hiệu hóa tài khoản; đặt lại
mật khẩu hộ người dùng; xem lịch sử đăng nhập.

**Cấu** **hình** **hệ** **thống:** Điều chỉnh giới hạn kích thước file
tải lên, giới hạn nội dung dùng thử cho khách, sĩ số tối đa lớp học,
thời gian gia hạn khi hết hạn gói. Đặt hạn mức AI hàng tháng cho từng
SME hoặc Teacher. Xem báo cáo sử dụng AI theo người dùng và loại tác vụ.
Điều chỉnh số lượng tối đa AI tạo mỗi lần.

**Theo** **dõi** **&** **vận** **hành:** Xem nhật ký hoạt động quan
trọng: đăng nhập bất thường, thay đổi phân quyền, giao dịch thanh toán,
lỗi hệ thống. Xem trạng thái kết nối các dịch vụ bên ngoài (AI, cổng
thanh toán, dịch vụ email). Nhận cảnh báo khi có sự cố. Thời gian lưu
giữ nhật ký được cấu hình qua CFG-B09.

**Điều** **kiện** **Chấp** **nhận:**

\- **AC-15a:** Tài khoản nội bộ mới nhận email mời trong vòng 60 giây
sau khi Admin tạo.

\- **AC-15b:** Vô hiệu hóa tài khoản đăng xuất ngay lập tức tất cả phiên
đang hoạt động của người dùng đó.

\- **AC-15c:** Danh sách người dùng hỗ trợ lọc và tìm kiếm theo tên,
email, vai trò và trạng thái. - **AC-15d:** Thay đổi cấu hình có hiệu
lực trong vòng 5 giây sau khi lưu.

\- **AC-15e:** Nhật ký hoạt động lưu theo CFG-B09 và có thể lọc theo
loại sự kiện, người thực hiện, khoảng thời gian.

\- **AC-15f:** Admin nhận cảnh báo trong vòng 5 phút khi dịch vụ bên
ngoài gặp sự cố.

**Điều** **kiện** **Không** **Chấp** **nhận:**

\- **NAC-15-a:** Không thể vô hiệu hóa tài khoản Admin duy nhất còn lại
trong hệ thống. - **NAC-15-b:** Admin không được xem mật khẩu của người
dùng — chỉ được đặt lại.

\- **NAC-15-c:** Thông tin bí mật (khóa API, mật khẩu SMTP) không hiển
thị dạng văn bản rõ trong giao diện sau khi đã lưu.

\- **NAC-15-d:** Không thể xóa nhật ký hoạt động qua giao diện — chỉ xóa
tự động theo chính sách lưu giữ.

Phần 4 — Quy tắc Nghiệp vụ

Chi tiết đầy đủ được quản lý trong **RTW.xlsx** **Sheet** **6**.

Nhóm A — Nội dung & Quyền Biên soạn

> • **BR-01:** Chỉ chuyên gia nội dung được phân công mới được tạo và
> sửa nội dung gốc của khóa học.
>
> • **BR-02:** Giảng viên không được sửa hoặc xóa nội dung từ khóa học
> gốc của chuyên gia. • **BR-03:** Lớp học luôn đọc nội dung trực tiếp
> từ khóa học gốc — không sao chép riêng.
>
> Khi chuyên gia cập nhật nội dung và xuất bản lại, tất cả lớp học thấy
> ngay.

Nhóm B — Soạn thảo & Nhập liệu

> • **BR-04:** Tệp đính kèm vượt giới hạn kích thước (CFG-B01) bị từ
> chối trước khi lưu.
>
> • **BR-05:** Học viên không được xem danh sách câu hỏi trong ngân hàng
> ngoài lúc đang làm bài kiểm tra.
>
> • **BR-06:** Điểm bài kiểm tra luyện tập không được ghi vào sổ điểm
> chính thức.
>
> • **BR-19:** Thẻ ghi nhớ trong một nhóm chỉ thuộc về module bài học
> chứa nhóm đó. • **BR-20:** Khi nhập hàng loạt (Excel hoặc CSV), từng
> dòng xử lý độc lập — dòng lỗi
>
> không chặn dòng hợp lệ. File mẫu phải được cung cấp sẵn cho người dùng
> tải về.

Nhóm C — AI Hỗ trợ & Kiểm duyệt

> • **BR-07:** Câu hỏi và thẻ ghi nhớ do AI tạo ra phải qua khu vực chờ
> duyệt và được chuyên gia phê duyệt trước khi sử dụng chính thức.
>
> • **BR-08:** Điểm chấm sơ bộ của hệ thống chỉ hiển thị cho giảng viên;
> học viên không xem được cho đến khi giảng viên xác nhận.
>
> • **BR-09:** Số lượng câu hỏi hoặc thẻ AI tạo mỗi lần không vượt quá
> giới hạn cấu hình (CFG-B02).
>
> • **BR-10:** Điểm cuối cùng bắt buộc phải được giảng viên xác nhận thủ
> công — hệ thống không tự động ghi điểm.

Nhóm D — Khách & Dùng thử

> • **BR-11:** Người dùng chưa đăng nhập không được sử dụng bất kỳ tính
> năng AI nào.
>
> • **BR-12:** Người dùng chưa đăng nhập chỉ được thử tối đa 10 câu hỏi
> mẫu và 5 thẻ ghi nhớ mẫu; vượt giới hạn chuyển đến trang đăng ký.

Nhóm E — Phân phối & Quyền Truy cập

> • **BR-13:** Course Manager chỉ thao tác trong phạm vi nhóm khóa học
> được Admin phân công — kiểm tra ở tầng xử lý nghiệp vụ, không chỉ ở
> giao diện.
>
> • **BR-14:** Chỉ Admin được tạo, xóa hoặc thay đổi cấu trúc nhóm khóa
> học.
>
> • **BR-15:** Một nhóm có thể có nhiều Course Manager; một Course
> Manager có thể phụ trách nhiều nhóm.
>
> • **BR-16:** Mỗi lần học viên truy cập nội dung có phí, hệ thống kiểm
> tra quyền truy cập còn hiệu lực.
>
> • **BR-17:** Khi hoàn tiền, quyền truy cập của học viên phải bị thu
> hồi trước, sau đó mới thực hiện hoàn tiền.
>
> • **BR-18:** Thu hồi quyền truy cập không xóa lịch sử học — tiến độ,
> kết quả kiểm tra, bài luận đều được giữ nguyên.

Nhóm F — Tài khoản & Xác thực

> • **BR-21:** Tài khoản đăng nhập bằng Google không có mật khẩu riêng
> trên EduNexus — không hiển thị và không cho phép dùng tính năng đổi
> mật khẩu.
>
> • **BR-22:** Đường dẫn đặt lại mật khẩu chỉ được dùng một lần và hết
> hiệu lực sau 1 giờ — không thể tái sử dụng.
>
> • **BR-23:** Sau khi đổi mật khẩu thành công, tất cả phiên đăng nhập
> khác bị đăng xuất trong vòng 5 giây để đảm bảo an toàn.
>
> • **BR-26** **(Mới):** Đăng ký bằng Google với email đã tồn tại trong
> hệ thống phải tự động liên kết tài khoản, không tạo tài khoản trùng
> lặp.
>
> • **BR-27** **(Mới):** Các vai trò nội bộ (SME, Teacher, Course
> Manager) chỉ được tạo bởi Admin qua FT-15 — không tự đăng ký được qua
> FT-14.

Nhóm G — Phân tích & Nhật ký (Mới — v2.4.0)

> • **BR-24:** Dữ liệu phân tích chỉ hiển thị dữ liệu tổng hợp cho
> Course Manager — không tiết lộ thông tin chi tiết của từng học viên.
>
> • **BR-25:** Nhật ký hoạt động hệ thống phải ghi đầy đủ: thời gian,
> người thực hiện, hành động và kết quả — không thể sửa hoặc xóa qua
> giao diện.

Phần 5 — Yêu cầu Hiệu năng & Kỹ thuật 5.1 Hiệu năng

**ID**

***NFR-P01***

***NFR-P02*** ***NFR-P03***

***NFR-P04***

***NFR-P05***

***NFR-P06***

***NFR-P07***

**Yêu** **cầu**

Tải trang bài học (FT-06)

Hiệu ứng lật thẻ ghi nhớ (FT-06)

Kiểm tra quyền truy cập nội dung

Cấp quyền sau thanh toán (FT-11)

Cập nhật bản xem trước bài giảng (FT-02)

Tải bảng tiến độ cá nhân (FT-12)

Tải báo cáo phân tích lớp học (FT-13)

**Chỉ** **tiêu**

95% dưới 1,0 giây

Dưới 100ms 99% dưới 50ms

Dưới 5 giây

Dưới 200ms

Dưới 1,5 giây

Dưới 2 giây

**Điều** **kiện**

500 concurrent users

Phía người dùng Có bộ đệm nhanh

Từ khi nhận xác nhận đến khi cấp quyền

Sau mỗi lần gõ phím (trễ 300ms)

Dữ liệu tối thiểu 3 tháng

Lớp tối đa 500 học viên

5.2 Bảo mật

**ID**

***NFR-SEC01***

***NFR-SEC02***

***NFR-SEC03***

***NFR-SEC04***

***NFR-SEC05***

***NFR-SEC06***

**Yêu** **cầu**

Toàn bộ kết nối phải dùng giao thức mã hóa; tự động chuyển sang kết nối
bảo mật nếu truy cập không bảo mật.

Phân quyền truy cập được kiểm tra ở cả tầng định tuyến URL và tầng xử lý
nghiệp vụ.

Chữ ký xác thực từ cổng thanh toán phải được kiểm tra trước khi xử lý
bất kỳ thông tin nào.

Thông tin cá nhân (email, tên) không được ghi vào nhật ký hệ thống hoặc
gửi cho dịch vụ AI.

Nội dung văn bản do người dùng nhập phải được lọc bỏ mã độc trước khi
lưu và hiển thị.

Mật khẩu được mã hóa một chiều mạnh trước khi lưu; không lưu mật khẩu
dạng thô.

***NFR-SEC07***

***NFR-SEC08***

Đường dẫn đặt lại mật khẩu dùng mã ngẫu nhiên không thể đoán được từ
thông tin người dùng.

Thông tin bí mật (khóa API cổng thanh toán, khóa AI) không được hiển thị
dạng văn bản rõ trong bất kỳ giao diện nào.

5.3 Độ Sẵn sàng

**ID**

***NFR-A01***

***NFR-A02***

***NFR-A03***

***NFR-A04***

**Yêu** **cầu**

Thời gian hoạt động tối thiểu 99,5% mỗi tháng cho các tính năng cốt lõi:
học bài giảng, ôn flashcard, làm bài kiểm tra, thanh toán, đăng nhập.

Khi dịch vụ AI gặp sự cố, các tính năng không dùng AI tiếp tục hoạt động
bình thường.

Có thể cập nhật phiên bản mới mà không cần dừng hệ thống.

Phục hồi sau sự cố hạ tầng trong vòng 1 giờ; mất dữ liệu tối đa 15 phút.

5.4 Khả năng Bảo trì

**ID**

***NFR-M01***

***NFR-M02***

***NFR-M03***

***NFR-M04***

**Yêu** **cầu**

Mọi thay đổi cấu trúc cơ sở dữ liệu phải qua quy trình migration có kiểm
soát; không sửa trực tiếp trên môi trường thực tế.

Nhật ký hệ thống phải có cấu trúc đủ để truy vết một yêu cầu từ đầu đến
cuối.

Độ phủ kiểm thử tối thiểu 70% cho lớp xử lý nghiệp vụ; 100% cho toàn bộ
quy tắc nghiệp vụ BR-01 đến BR-25.

Kết nối đến dịch vụ AI và cổng thanh toán phải thiết kế để có thể thay
thế nhà cung cấp mà không ảnh hưởng logic nghiệp vụ.

5.5 Tích hợp Bên ngoài

**ID**

***NFR-API01***

***NFR-API02***

**Yêu** **cầu**

Khi nhận được thông báo thanh toán trùng lặp, hệ thống chỉ xử lý một lần
— không cấp quyền hai lần.

Kết nối đến dịch vụ AI phải có cơ chế tự động thử lại khi gặp lỗi tạm
thời và timeout sau 30 giây.

Phần 6 — Danh mục Thông báo

**NTF** **ID** **Sự** **kiện** **kích** **hoạt**

***NTF-01*** Học viên nộp bài luận

***NTF-02*** AI hoàn thành tạo nội dung gợi ý

***NTF-03*** Thanh toán thành công

**Người** **nhận** Giảng viên

SME

Học viên

**Kênh**

Trong ứng dụng

Trong ứng dụng

Email + Đẩy thông báo

**Thời** **gian** Ngay lập tức

Ngay lập tức

Trong vòng 30 giây

**FT**

FT-08

FT-03, FT-04

FT-11

***NTF-04*** Thanh toán thất bại

***NTF-05*** Gói đăng ký sắp hết hạn

***NTF-06*** Gói đăng ký đã hết hạn

***NTF-07*** Đăng ký lớp học thành công

***NTF-08*** Lớp học sắp khai giảng

***NTF-09*** Sắp đạt giới hạn hạn mức AI

***NTF-10*** Điểm bài luận đã được xác nhận

***NTF-11*** Sắp đến hạn nộp bài luận

***NTF-12*** Email xác minh tài khoản

***NTF-13*** Đường dẫn đặt lại mật khẩu

***NTF-14*** Tài khoản nội bộ mới được Admin tạo

***NTF-15*** Học viên không hoạt động quá 7 ngày

Học viên

Học viên

Học viên

Học viên

Học viên đã đăng ký

SME / Giảng viên

Học viên

Học viên chưa nộp

Người dùng mới đăng ký bằng email

Người dùng yêu cầu

SME / Teacher / Manager mới

Giảng viên

Email + Đẩy thông báo

Email + Đẩy thông báo

Email + Trong ứng dụng

Email

Email + Đẩy thông báo

Trong ứng dụng

Đẩy thông báo + Trong ứng dụng

Đẩy thông báo + Trong ứng dụng

Email

Email

Email

Trong ứng dụng

Trong vòng 30 giây

7 ngày trước + 1 ngày trước

Ngay khi thu hồi quyền

Trong vòng 60 giây

24 giờ trước ngày khai giảng

Khi đạt 80% hạn mức tháng

Ngay khi giảng viên xác nhận

24 giờ trước hạn nộp

Trong vòng 60 giây

Trong vòng 60 giây

Trong vòng 60 giây

Mỗi ngày một lần

FT-11

FT-10

FT-10

FT-09

FT-09

FT-02, FT-03, FT-04

FT-08

FT-08

FT-14

FT-14

FT-15

FT-13

*—* *Kết* *thúc* *Đặc* *tả* *Yêu* *cầu* *Phần* *mềm* *—* *Project*
*EduNexus* *SRS* *v2* *—*
