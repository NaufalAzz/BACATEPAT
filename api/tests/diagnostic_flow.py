"""Integration test for a disposable MySQL database with the development seed.

Run with BACATEPAT_TEST_URL=http://localhost:8000/api/v1 and BACATEPAT_DEMO_PASSWORD.
Creates a class, a student, four questions, a test and one completed attempt.
"""
import json
import time
import os
import uuid
from urllib.error import HTTPError
from urllib.request import Request, urlopen

base = os.environ["BACATEPAT_TEST_URL"].rstrip("/")
password = os.environ["BACATEPAT_DEMO_PASSWORD"]
suffix = uuid.uuid4().hex[:10]


def call(method, path, body=None, token=None, expected=200):
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = Request(base + "/" + path, method=method, headers=headers,
                      data=None if body is None else json.dumps(body).encode())
    for attempt in range(2):
        try:
            response = urlopen(request, timeout=15)
        except HTTPError as error:
            response = error
        if response.status != 429 or expected == 429 or attempt:
            break
        delay = int(response.headers.get("Retry-After", "60"))
        response.close()
        time.sleep(min(delay, 60) + 1)
    with response:
        assert response.status == expected, (path, response.status, expected)
        return json.load(response)


def login(name):
    return call("POST", "auth/login", {"username": name, "password": password,
                                       "device_name": "integration"})["data"]["token"]


teacher = login("demo.guru.rina")
room = call("POST", "guru/kelas", {"nama_kelas": suffix, "tingkat": 1,
                                   "tahun_ajaran": "2026/2027"}, teacher, 201)["data"]["id"]
username = "test." + suffix
created_student = call("POST", "guru/siswa", {"nama": "Siswa uji", "username": username, "password": password,
                            "kelas_id": room, "nama_wali": "Wali uji"}, teacher, 201)
student = login(username)
assert call("GET", "auth/me", token=student)["data"]["kelas"] == suffix
call("GET", "guru/siswa", token=student, expected=403)
questions = []
for i, aspect in enumerate(["huruf", "suku_kata", "kata", "kalimat"], 1):
    question = call("POST", "guru/soal", {"aspek": aspect, "tingkat_kesulitan": 1,
        "tipe": "pilihan_ganda", "penggunaan": "diagnostik", "pertanyaan": "Pilih A",
        "opsi_jawaban": ["A", "B"], "kunci_jawaban": "A"}, teacher, 201)["data"]["id"]
    call("PATCH", f"guru/soal/{question}/review", {"status_review": "disetujui"}, teacher)
    questions.append({"soal_id": question, "urutan": i})
test = call("POST", "guru/diagnostik", {"judul": suffix, "kelas_id": room, "soal": questions},
            teacher, 201)["data"]["id"]
call("PATCH", f"guru/diagnostik/{test}/status", {"status": "aktif"}, teacher)
attempt = call("POST", "siswa/diagnostik/mulai", {"tes_id": test}, student, 201)["data"]
path = f"siswa/diagnostik/hasil/{attempt['hasil_id']}"
call("POST", path + "/selesai", {}, student, 422)
assert attempt == call("POST", "siswa/diagnostik/mulai", {"tes_id": test}, student)["data"]
for question in attempt["soal"]:
    assert set(question) == {"id","soal_id","pertanyaan","teks_target","stimulus","tipe","jawaban","opsi","terkirim"}
    call("POST", path + "/jawaban", {"soal_id": question["soal_id"], "jawaban": "A"}, student)
result = call("POST", path + "/selesai", {}, student)["data"]
assert result["status"] == "completed" and all(v == 100 for v in result["skor"].values())
assert result == call("POST", path + "/selesai", {}, student)["data"]
# Practice reads the teacher's active material and grades the saved answer snapshot.
material = call("POST", "guru/materi", {"judul": suffix, "aspek":"huruf","tingkat_kesulitan":1,"konten":"Huruf A"},teacher,201)["data"]["id"]
call("PATCH", f"guru/materi/{material}/status", {"status":"aktif"},teacher)
q = call("POST", "guru/soal", {"materi_id":material,"aspek":"huruf","tingkat_kesulitan":1,"tipe":"pilihan_ganda",
    "penggunaan":"latihan","pertanyaan":"Pilih A","opsi_jawaban":["A","B"],"kunci_jawaban":"A"},teacher,201)["data"]["id"]
call("PATCH",f"guru/soal/{q}/review",{"status_review":"disetujui"},teacher)
practice = call("POST","siswa/latihan/mulai",{"materi_id":material},student,201)["data"]["hasil_id"]
call("POST",f"siswa/latihan/{practice}/jawaban",{"soal_id":q,"jawaban":"B"},student)
assert float(call("POST",f"siswa/latihan/{practice}/selesai",{},student)["data"]["skor"]) == 0
progress = call("GET","siswa/perkembangan",token=student)["data"]["aspek"]
assert len(progress["huruf"]) == 2
# The third low result at level one should open teacher follow-up.
for _ in range(2):
    practice = call("POST","siswa/latihan/mulai",{"materi_id":material},student,201)["data"]["hasil_id"]
    call("POST",f"siswa/latihan/{practice}/jawaban",{"soal_id":q,"jawaban":"B"},student)
    call("POST",f"siswa/latihan/{practice}/selesai",{},student)
student_id = created_student["data"]["siswa_id"]
flags = call("GET",f"guru/pendampingan?kelas_id={room}",token=teacher)["data"]
assert [flag["siswa_id"] for flag in flags] == [student_id]
call("PATCH",f"guru/siswa/{student_id}/pendampingan",{"perlu_pendampingan":False},teacher)
assert call("GET",f"guru/pendampingan?kelas_id={room}",token=teacher)["data"] == []
call("PUT",f"guru/siswa/{student_id}/rekomendasi",{"materi_id":material,"alasan":"Penguatan huruf"},teacher)
assert call("GET","siswa/beranda",token=student)["data"]["rekomendasi"]["materi_id"] == material
with urlopen(Request(base+f"/guru/laporan/kelas/{room}",headers={"Authorization":"Bearer "+teacher})) as report:
    assert report.headers.get_content_type() == "application/pdf" and report.read(4) == b"%PDF"
call("POST","guru/ai/materi",{"aspek":"huruf","tema":"buah","tingkat":1,"jumlah":1},teacher,503)
# Oral practice requires guardian consent and a private upload. The teacher's
# evaluation must finalize the exercise without any AI provider configured.
oral_material = call("POST","guru/materi",{"judul":"Baca kata","aspek":"kata","tingkat_kesulitan":1,"konten":"Bola"},teacher,201)["data"]["id"]
call("PATCH",f"guru/materi/{oral_material}/status",{"status":"aktif"},teacher)
oral_question = call("POST","guru/soal",{"materi_id":oral_material,"aspek":"kata","tingkat_kesulitan":1,"tipe":"baca_lisan",
    "penggunaan":"latihan","pertanyaan":"Baca kata ini","teks_target":"Bola"},teacher,201)["data"]["id"]
call("PATCH",f"guru/soal/{oral_question}/review",{"status_review":"disetujui"},teacher)
oral_attempt = call("POST","siswa/latihan/mulai",{"materi_id":oral_material},student,201)["data"]["hasil_id"]
import io
import wave
audio = io.BytesIO()
with wave.open(audio,"wb") as wav:
    wav.setparams((1,2,8000,0,"NONE","not compressed"))
    wav.writeframes(b"\0" * 32000)
boundary = "bacatepat-" + suffix
parts = []
for key,value in {"soal_id":oral_question,"hasil_latihan_id":oral_attempt}.items():
    parts.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{key}"\r\n\r\n{value}\r\n'.encode())
parts += [f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="test.wav"\r\nContent-Type: audio/wav\r\n\r\n'.encode(),
          audio.getvalue(),f'\r\n--{boundary}--\r\n'.encode()]
upload = Request(base+"/siswa/rekaman",data=b"".join(parts),headers={"Accept":"application/json","Authorization":"Bearer "+student,"Content-Type":"multipart/form-data; boundary="+boundary})
try:
    urlopen(upload)
    raise AssertionError("upload without guardian consent")
except HTTPError as error:
    assert error.code == 403
student_id = created_student["data"]["siswa_id"]
call("PUT",f"guru/siswa/{student_id}/persetujuan",{"persetujuan_wali":True,"persetujuan_ai":False},teacher)
with urlopen(upload) as response:
    recording = json.load(response)["data"]["rekaman_id"]
call("POST",f"siswa/latihan/{oral_attempt}/selesai",{},student)
evaluation=call("POST",f"guru/rekaman/{recording}/evaluasi",{"nilai_ketepatan":70,"nilai_kelancaran":80,"komentar":"Terbaca","saran":"Ulangi perlahan"},teacher,201)
assert float(call("POST",f"siswa/latihan/{oral_attempt}/selesai",{},student)["data"]["skor"]) == 75
evaluation_id = evaluation["data"]["evaluasi_id"]
revision = {"nilai_ketepatan":90,"nilai_kelancaran":90,"komentar":"Direvisi","saran":"Lanjut","revision":1}
for _ in range(2):
    assert call("PUT", f"guru/evaluasi/{evaluation_id}",revision,teacher)["data"]["revision"] == 2
call("PUT", f"guru/evaluasi/{evaluation_id}",dict(revision,komentar="Versi lama"),teacher,409)
call("PUT", f"guru/evaluasi/{evaluation_id}",revision,student,403)
assert float(call("POST",f"siswa/latihan/{oral_attempt}/selesai",{},student)["data"]["skor"]) == 90
assert call("GET","siswa/evaluasi",token=student)["data"][0]["comment"] == "Direvisi"
# Follow the same class/profile paths as the teacher dashboard.
assert call("GET","guru/dashboard",token=teacher)["data"]["siswa"] >= 1
history = f"guru/siswa/{student_id}"
assert call("GET",history+"/diagnostik",token=teacher)["data"][0]["judul"] == suffix
assert call("GET",history+"/latihan",token=teacher)["data"][0]["judul"] == "Baca kata"
assert call("GET",history+"/evaluasi",token=teacher)["data"][0]["comment"] == "Direvisi"
call("GET",history+"/evaluasi",token=student,expected=403)
for token in [student, teacher]:
    call("POST", "auth/logout", {}, token)
    call("GET", "auth/me", token=token, expected=401)
print("Diagnostic workflow passed")
