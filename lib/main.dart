import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Sistem Penggajian Mobile', home: HomeScreen());
  }
}

// DATABASE HELPER
class DatabaseHelper {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'penggajian.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE karyawan(id INTEGER PRIMARY KEY AUTOINCREMENT, nama TEXT, jabatan TEXT, gajiPokok REAL, tunjangan REAL, potongan REAL, totalGaji REAL)',
        );
      },
      version: 1,
    );
    return _db!;
  }

  static Future<void> tambah(Map<String, dynamic> data) async {
    final db = await getDB();
    await db.insert('karyawan', data);
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final db = await getDB();
    return db.query('karyawan');
  }

  static Future<void> update(Map<String, dynamic> data) async {
    final db = await getDB();
    await db.update('karyawan', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  static Future<void> hapus(int id) async {
    final db = await getDB();
    await db.delete('karyawan', where: 'id = ?', whereArgs: [id]);
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final data = await DatabaseHelper.getAll();
    setState(() => _list = data);
  }

  void _hapus(int id) async {
    await DatabaseHelper.hapus(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sistem Penggajian Mobile')),
      body: _list.isEmpty
          ? Center(child: Text('Belum ada data karyawan'))
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (context, i) {
                final k = _list[i];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(k['nama']),
                    subtitle: Text(
                      '${k['jabatan']} - Total: Rp ${k['totalGaji']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormScreen(data: k),
                              ),
                            );
                            _loadData();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _hapus(k['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FormScreen()),
          );
          _loadData();
        },
      ),
    );
  }
}

// FORM SCREEN
class FormScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  FormScreen({this.data});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _nama = TextEditingController();
  final _jabatan = TextEditingController();
  final _gaji = TextEditingController();
  final _tunjangan = TextEditingController();
  final _potongan = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _nama.text = widget.data!['nama'];
      _jabatan.text = widget.data!['jabatan'];
      _gaji.text = widget.data!['gajiPokok'].toString();
      _tunjangan.text = widget.data!['tunjangan'].toString();
      _potongan.text = widget.data!['potongan'].toString();
    }
  }

  void _simpan() async {
    double gaji = double.parse(_gaji.text);
    double tunjangan = double.parse(_tunjangan.text);
    double potongan = double.parse(_potongan.text);
    double total = gaji + tunjangan - potongan;

    final data = {
      'nama': _nama.text,
      'jabatan': _jabatan.text,
      'gajiPokok': gaji,
      'tunjangan': tunjangan,
      'potongan': potongan,
      'totalGaji': total,
    };

    if (widget.data == null) {
      await DatabaseHelper.tambah(data);
    } else {
      data['id'] = widget.data!['id'];
      await DatabaseHelper.update(data);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data == null ? 'Tambah Karyawan' : 'Edit Karyawan'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nama,
              decoration: InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: _jabatan,
              decoration: InputDecoration(labelText: 'Jabatan'),
            ),
            TextField(
              controller: _gaji,
              decoration: InputDecoration(labelText: 'Gaji Pokok'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _tunjangan,
              decoration: InputDecoration(labelText: 'Tunjangan'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _potongan,
              decoration: InputDecoration(labelText: 'Potongan'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _simpan, child: Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
