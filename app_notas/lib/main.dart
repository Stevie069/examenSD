import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainScreen()));
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // ⚠️ TU IP REAL (Broker)
  final String broker = '10.134.123.31'; 
  late MqttServerClient client;
  bool _conectado = false;

  String _resultado = "--";
  List<dynamic> _historial = [];
  bool _cargando = false;

  // Controladores y Variables (Igual que antes)
  final _ageCtrl = TextEditingController(text: "20");
  final _studyCtrl = TextEditingController(text: "5");
  final _attendCtrl = TextEditingController(text: "90");
  final _sleepCtrl = TextEditingController(text: "8");

  String _gender = 'male';
  String _course = 'diploma';
  String _internet = 'yes';
  String _sleepQual = 'average';
  String _method = 'coaching';
  String _facility = 'moderate';
  String _difficulty = 'moderate';

  // Mapas de Traducción (Igual que antes)
  final Map<String, String> mapGender = {'male': 'Masculino', 'female': 'Femenino', 'other': 'Otro'};
  final Map<String, String> mapCourse = {'diploma': 'Diplomado', 'b.sc': 'Licenciatura', 'bca': 'Ing. Sistemas', 'b.tech': 'Tecnología', 'm.sc': 'Maestría', 'm.tech': 'Maestría Tec'};
  final Map<String, String> mapYesNo = {'yes': 'Sí', 'no': 'No'};
  final Map<String, String> mapQuality = {'poor': 'Mala', 'average': 'Regular', 'good': 'Buena'};
  final Map<String, String> mapMethod = {'coaching': 'Tutoría', 'online videos': 'Videos Online', 'self study': 'Autoestudio'};
  final Map<String, String> mapLevel = {'low': 'Baja', 'moderate': 'Moderada', 'high': 'Alta'};
  final Map<String, String> mapDifficulty = {'low': 'Baja', 'moderate': 'Moderada', 'high': 'Alta', 'hard': 'Muy Difícil'};

  @override
  void initState() {
    super.initState();
    _conectarMQTT();
  }

  Future<void> _conectarMQTT() async {
    client = MqttServerClient(broker, 'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 1883;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    
    try {
      await client.connect();
      client.subscribe("escuela/predict/response", MqttQos.atMostOnce);
      client.subscribe("escuela/history/response", MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = c[0].topic;

        final data = jsonDecode(pt);
        setState(() {
          if (topic == "escuela/predict/response") {
            _resultado = data['score'].toString();
            _cargando = false;
            _pedirHistorial(); // Actualizar historial al recibir predicción
          } else if (topic == "escuela/history/response") {
            _historial = data;
          }
        });
      });

      setState(() { _conectado = true; });
      _pedirHistorial(); // Pedir historial al conectar

    } catch (e) {
      print('❌ Error MQTT: $e');
      client.disconnect();
    }
  }

  void _enviarPrediccion() {
    if (!_conectado) return;
    FocusScope.of(context).unfocus();
    setState(() { _cargando = true; _resultado = "⏳"; });

    final jsonString = jsonEncode({
      "age": _ageCtrl.text, "gender": _gender, "course": _course,
      "study_hours": _studyCtrl.text, "class_attendance": _attendCtrl.text,
      "internet_access": _internet, "sleep_hours": _sleepCtrl.text,
      "sleep_quality": _sleepQual, "study_method": _method,
      "facility_rating": _facility, "exam_difficulty": _difficulty
    });

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonString);
    client.publishMessage("escuela/predict/request", MqttQos.atLeastOnce, builder.payload!);
  }

  void _pedirHistorial() {
    if (!_conectado) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString("{}");
    client.publishMessage("escuela/history/request", MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_conectado ? "🟢 Sistema Distribuido" : "🔴 Desconectado"),
        backgroundColor: _conectado ? Colors.green[700] : Colors.red,
      ),
      body: _currentIndex == 0 ? _buildPredict() : _buildHistory(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() {
          _currentIndex = i;
          if (i == 1) { FocusScope.of(context).unfocus(); _pedirHistorial(); }
        }),
        selectedItemColor: Colors.green[800],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: "Predecir"),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Historial"),
        ],
      ),
    );
  }

  // --- VISTA PREDICCIÓN ---
  Widget _buildPredict() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(children: [
               _numInput("Edad", Icons.person, _ageCtrl),
               _drop("Género", _gender, mapGender, (v) => setState(() => _gender = v!)),
               _drop("Curso", _course, mapCourse, (v) => setState(() => _course = v!)),
               _numInput("Horas Estudio", Icons.timer, _studyCtrl),
               _numInput("Asistencia %", Icons.percent, _attendCtrl),
               _drop("Internet", _internet, mapYesNo, (v) => setState(() => _internet = v!)),
               _numInput("Horas Sueño", Icons.bed, _sleepCtrl),
               _drop("Calidad Sueño", _sleepQual, mapQuality, (v) => setState(() => _sleepQual = v!)),
               _drop("Método", _method, mapMethod, (v) => setState(() => _method = v!)),
               _drop("Instalaciones", _facility, mapLevel, (v) => setState(() => _facility = v!)),
               _drop("Dificultad", _difficulty, mapDifficulty, (v) => setState(() => _difficulty = v!)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _cargando || !_conectado ? null : _enviarPrediccion,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
          child: Text(_cargando ? "PROCESANDO..." : "PUBLICAR EN MQTT"),
        ),
        const SizedBox(height: 20),
        Text("Respuesta del Broker:", style: TextStyle(color: Colors.grey)),
        Text(_resultado, style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.green[800])),
      ]),
    );
  }

  Widget _numInput(String label, IconData icon, TextEditingController ctrl) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder())));
  }
  
  Widget _drop(String label, String val, Map<String, String> items, Function(String?) changed) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
      value: items.containsKey(val) ? val : items.keys.first,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: changed,
    ));
  }

  // --- VISTA HISTORIAL ---
  Widget _buildHistory() {
    return ListView.builder(
      itemCount: _historial.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (ctx, i) {
        final item = _historial[i];
        return Card(child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.green[100], child: FittedBox(child: Text(item['score'].toString()))),
          title: Text("Nota: ${item['score']}", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Estudio: ${item['study']}h | Asist: ${item['attend']}%"),
          trailing: Text(item['date']),
        ));
      },
    );
  }
}