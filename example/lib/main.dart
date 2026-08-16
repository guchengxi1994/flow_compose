import 'dart:convert';

import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const FlowComposeExample());

class FlowComposeExample extends StatelessWidget {
  const FlowComposeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flow Compose',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF226D68),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFEFE),
      ),
      home: const WorkflowEditor(),
    );
  }
}

class WorkflowEditor extends StatefulWidget {
  const WorkflowEditor({super.key});

  @override
  State<WorkflowEditor> createState() => _WorkflowEditorState();
}

class _WorkflowEditorState extends State<WorkflowEditor> {
  late final FlowController controller = FlowController();

  @override
  void initState() {
    super.initState();
    controller.registerNodes(_definitions);

    final trigger = controller.addNode('trigger', const Offset(80, 220));
    final prompt = controller.addNode('prompt', const Offset(430, 180), data: {
      'instruction': 'Summarize the incoming request in a concise answer.',
    });
    final database = controller.addNode('database', const Offset(430, 390));
    final response = controller.addNode('response', const Offset(800, 240));
    controller.connect(
        FlowPortRef(trigger.id, 'event'), FlowPortRef(prompt.id, 'input'));
    controller.connect(
        FlowPortRef(database.id, 'rows'), FlowPortRef(prompt.id, 'context'));
    controller.connect(
        FlowPortRef(prompt.id, 'answer'), FlowPortRef(response.id, 'content'));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 54,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 21),
            SizedBox(width: 9),
            Text('Flow Compose',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Validate and view workflow JSON',
            child: IconButton(
              onPressed: _showWorkflowJson,
              icon: const Icon(Icons.data_object_outlined),
            ),
          ),
          Tooltip(
            message: 'Clear workflow',
            child: IconButton(
              onPressed: controller.clear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FlowCanvas(controller: controller),
    );
  }

  void _showWorkflowJson() {
    final issues = controller.validateGraph();
    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(issues.first.message)),
      );
      return;
    }

    final source =
        const JsonEncoder.withIndent('  ').convert(controller.graph.toJson());
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.78,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Workflow JSON',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy JSON',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: source));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Workflow JSON copied')),
                        );
                      },
                      icon: const Icon(Icons.content_copy_outlined),
                    ),
                    IconButton(
                      tooltip: 'Close JSON',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        source,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFF22313A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _definitions = <FlowNodeDefinition>[
  FlowNodeDefinition(
    type: 'trigger',
    title: 'Start trigger',
    description: 'Begins a workflow from an incoming event.',
    size: const Size(224, 116),
    outputs: const [
      FlowPort(
        id: 'event',
        label: 'Event',
        kind: FlowPortKind.output,
        dataType: FlowDataType.object,
      ),
    ],
    icon: Icons.play_arrow_rounded,
    accentColor: const Color(0xFF117C62),
    canvasBuilder: (context, node) => const _NodeSummary(
      label: 'Webhook event',
      detail: 'POST /support/request',
    ),
    configurationBuilder: (context, node, onChanged) => _TextNodeConfiguration(
      node: node,
      keyName: 'path',
      label: 'Webhook path',
      hint: '/support/request',
      onChanged: onChanged,
    ),
  ),
  FlowNodeDefinition(
    type: 'database',
    title: 'Database query',
    description: 'Looks up structured context for a request.',
    size: const Size(248, 136),
    inputs: const [
      FlowPort(
        id: 'query',
        label: 'Query',
        kind: FlowPortKind.input,
        dataType: FlowDataType.object,
      ),
    ],
    outputs: const [
      FlowPort(
        id: 'rows',
        label: 'Rows',
        kind: FlowPortKind.output,
        dataType: FlowDataType.array,
      ),
    ],
    initialData: {'table': 'customer_tickets'},
    icon: Icons.storage_outlined,
    accentColor: const Color(0xFF3269A8),
    canvasBuilder: (context, node) => _NodeSummary(
      label: 'Source table',
      detail: node.data['table']?.toString() ?? 'customer_tickets',
    ),
    configurationBuilder: (context, node, onChanged) => _TextNodeConfiguration(
      node: node,
      keyName: 'table',
      label: 'Source table',
      hint: 'customer_tickets',
      onChanged: onChanged,
    ),
  ),
  FlowNodeDefinition(
    type: 'prompt',
    title: 'AI prompt',
    description: 'Generates a response from request and context.',
    size: const Size(278, 162),
    inputs: const [
      FlowPort(
        id: 'input',
        label: 'Request',
        kind: FlowPortKind.input,
        dataType: FlowDataType.object,
        isRequired: true,
      ),
      FlowPort(
        id: 'context',
        label: 'Context',
        kind: FlowPortKind.input,
        dataType: FlowDataType.array,
      ),
    ],
    outputs: const [
      FlowPort(
        id: 'answer',
        label: 'Answer',
        kind: FlowPortKind.output,
        dataType: FlowDataType.string,
      ),
    ],
    initialData: {
      'model': 'gpt-5-mini',
      'instruction': 'Summarize the incoming request in a concise answer.',
    },
    icon: Icons.auto_awesome_outlined,
    accentColor: const Color(0xFF8D4F9B),
    canvasBuilder: (context, node) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(node.data['model']?.toString() ?? 'gpt-5-mini',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        Text(node.data['instruction']?.toString() ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF60737E), height: 1.35)),
      ],
    ),
    configurationBuilder: (context, node, onChanged) => _PromptConfiguration(
      node: node,
      onChanged: onChanged,
    ),
  ),
  FlowNodeDefinition(
    type: 'response',
    title: 'Send response',
    description: 'Returns the final message to the caller.',
    size: const Size(224, 116),
    inputs: const [
      FlowPort(
        id: 'content',
        label: 'Content',
        kind: FlowPortKind.input,
        dataType: FlowDataType.string,
        isRequired: true,
        allowMultipleConnections: false,
      ),
    ],
    icon: Icons.send_outlined,
    accentColor: const Color(0xFFC65C38),
    canvasBuilder: (context, node) => const _NodeSummary(
      label: 'HTTP response',
      detail: '200 application/json',
    ),
    configurationBuilder: (context, node, onChanged) => _TextNodeConfiguration(
      node: node,
      keyName: 'statusCode',
      label: 'Status code',
      hint: '200',
      onChanged: onChanged,
    ),
  ),
];

class _NodeSummary extends StatelessWidget {
  const _NodeSummary({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Text(detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF60737E))),
        ],
      );
}

class _TextNodeConfiguration extends StatefulWidget {
  const _TextNodeConfiguration({
    required this.node,
    required this.keyName,
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final FlowNode node;
  final String keyName;
  final String label;
  final String hint;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<_TextNodeConfiguration> createState() => _TextNodeConfigurationState();
}

class _TextNodeConfigurationState extends State<_TextNodeConfiguration> {
  late final TextEditingController _text = TextEditingController(
    text: widget.node.data[widget.keyName]?.toString() ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            onChanged: (value) =>
                widget.onChanged({...widget.node.data, widget.keyName: value}),
            decoration: InputDecoration(
                hintText: widget.hint, border: const OutlineInputBorder()),
          ),
        ],
      );
}

class _PromptConfiguration extends StatefulWidget {
  const _PromptConfiguration({required this.node, required this.onChanged});

  final FlowNode node;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<_PromptConfiguration> createState() => _PromptConfigurationState();
}

class _PromptConfigurationState extends State<_PromptConfiguration> {
  late final TextEditingController _model = TextEditingController(
    text: widget.node.data['model']?.toString() ?? 'gpt-5-mini',
  );
  late final TextEditingController _instruction = TextEditingController(
    text: widget.node.data['instruction']?.toString() ?? '',
  );

  void _save() => widget.onChanged({
        ...widget.node.data,
        'model': _model.text,
        'instruction': _instruction.text,
      });

  @override
  void dispose() {
    _model.dispose();
    _instruction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Model', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _model,
            onChanged: (_) => _save(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text('Instruction',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _instruction,
            onChanged: (_) => _save(),
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      );
}
