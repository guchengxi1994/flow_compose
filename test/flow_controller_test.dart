import 'package:flow_compose/flow_compose.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlowController controller;

  setUp(() {
    controller = FlowController();
    controller.registerNodes(const [
      FlowNodeDefinition(
        type: 'source',
        title: 'Source',
        description: 'Test source',
        outputs: [
          FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.output),
        ],
      ),
      FlowNodeDefinition(
        type: 'target',
        title: 'Target',
        description: 'Test target',
        inputs: [
          FlowPort(
            id: 'value',
            label: 'Value',
            kind: FlowPortKind.input,
            allowMultipleConnections: false,
          ),
        ],
      ),
      FlowNodeDefinition(
        type: 'multiTarget',
        title: 'Multi target',
        description: 'Test target with multiple incoming values',
        inputs: [
          FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.input),
        ],
      ),
    ]);
  });

  test('rejects a second source for a single-input port', () {
    final firstSource = controller.addNode('source', const Offset(0, 0));
    final secondSource = controller.addNode('source', const Offset(0, 200));
    final target = controller.addNode('target', const Offset(400, 0));
    final input = FlowPortRef(target.id, 'value');

    expect(controller.connect(FlowPortRef(firstSource.id, 'value'), input),
        isTrue);
    expect(controller.connect(FlowPortRef(secondSource.id, 'value'), input),
        isFalse);
    expect(controller.graph.edges, hasLength(1));
    expect(controller.graph.edges.single.source.nodeId, firstSource.id);
  });

  test('retains existing edges for a multi-connection input', () {
    final firstSource = controller.addNode('source', const Offset(0, 0));
    final secondSource = controller.addNode('source', const Offset(0, 200));
    final target = controller.addNode('multiTarget', const Offset(400, 0));
    final input = FlowPortRef(target.id, 'value');

    expect(controller.connect(FlowPortRef(firstSource.id, 'value'), input),
        isTrue);
    expect(controller.connect(FlowPortRef(secondSource.id, 'value'), input),
        isTrue);
    expect(controller.graph.edges, hasLength(2));
    expect(
      controller.graph.edges.map((edge) => edge.source.nodeId),
      containsAll([firstSource.id, secondSource.id]),
    );
  });

  test('rejects incompatible data types before mutating the graph', () {
    controller.registerNodes(const [
      FlowNodeDefinition(
        type: 'textSource',
        title: 'Text source',
        description: 'Test text source',
        outputs: [
          FlowPort(
            id: 'value',
            label: 'Value',
            kind: FlowPortKind.output,
            dataType: FlowDataType.string,
          ),
        ],
      ),
      FlowNodeDefinition(
        type: 'arraySource',
        title: 'Array source',
        description: 'Test array source',
        outputs: [
          FlowPort(
            id: 'value',
            label: 'Value',
            kind: FlowPortKind.output,
            dataType: FlowDataType.array,
          ),
        ],
      ),
      FlowNodeDefinition(
        type: 'textTarget',
        title: 'Text target',
        description: 'Test text target',
        inputs: [
          FlowPort(
            id: 'value',
            label: 'Value',
            kind: FlowPortKind.input,
            dataType: FlowDataType.string,
          ),
        ],
      ),
    ]);
    final text = controller.addNode('textSource', const Offset(0, 0));
    final array = controller.addNode('arraySource', const Offset(0, 200));
    final target = controller.addNode('textTarget', const Offset(400, 0));
    final targetRef = FlowPortRef(target.id, 'value');

    expect(
        controller.connect(FlowPortRef(text.id, 'value'), targetRef), isTrue);
    final validation = controller.validateConnection(
        FlowPortRef(array.id, 'value'), targetRef);
    expect(validation.isValid, isFalse);
    expect(validation.issue?.code, FlowValidationCode.incompatibleDataTypes);
    expect(
      () =>
          controller.connectOrThrow(FlowPortRef(array.id, 'value'), targetRef),
      throwsA(isA<FlowConnectionException>()),
    );
    expect(controller.graph.edges, hasLength(1));
  });

  test('reports missing required inputs when validating a graph', () {
    controller.registerNode(const FlowNodeDefinition(
      type: 'requiredTarget',
      title: 'Required target',
      description: 'Test required input',
      inputs: [
        FlowPort(
          id: 'value',
          label: 'Value',
          kind: FlowPortKind.input,
          isRequired: true,
        ),
      ],
    ));
    controller.addNode('requiredTarget', const Offset(400, 0));

    expect(
      controller.validateGraph().map((issue) => issue.code),
      contains(FlowValidationCode.missingRequiredInput),
    );
  });

  test('rejects self-connections, wrong directions, and duplicate edges', () {
    final source = controller.addNode('source', const Offset(0, 0));
    final target = controller.addNode('target', const Offset(400, 0));
    final output = FlowPortRef(source.id, 'value');
    final input = FlowPortRef(target.id, 'value');

    expect(
        controller.connect(output, FlowPortRef(source.id, 'value')), isFalse);
    expect(controller.connect(input, output), isFalse);
    expect(controller.connect(output, input), isTrue);
    expect(controller.connect(output, input), isFalse);
  });

  test('reconnects an existing edge without changing its source', () {
    final source = controller.addNode('source', const Offset(0, 0));
    final firstTarget = controller.addNode('target', const Offset(400, 0));
    final secondTarget = controller.addNode('target', const Offset(400, 200));
    controller.connect(
      FlowPortRef(source.id, 'value'),
      FlowPortRef(firstTarget.id, 'value'),
    );

    final edgeId = controller.graph.edges.single.id;
    expect(
      controller.reconnectEdgeTarget(
        edgeId,
        FlowPortRef(secondTarget.id, 'value'),
      ),
      isTrue,
    );
    expect(controller.graph.edges, hasLength(1));
    expect(controller.graph.edges.single.id, edgeId);
    expect(controller.graph.edges.single.source.nodeId, source.id);
    expect(controller.graph.edges.single.target.nodeId, secondTarget.id);
  });

  test('graph JSON preserves node data and port references', () {
    final source = controller.addNode(
      'source',
      const Offset(12, 24),
      data: {'message': 'hello'},
    );
    final target = controller.addNode('target', const Offset(300, 24));
    controller.connect(
      FlowPortRef(source.id, 'value'),
      FlowPortRef(target.id, 'value'),
    );

    final restored = FlowGraph.fromJson(controller.graph.toJson());
    expect(restored.nodes.single.data['message'], 'hello');
    expect(restored.nodes.first.position, const Offset(12, 24));
    expect(restored.edges.single.source.portId, 'value');
    expect(restored.edges.single.target.nodeId, target.id);
  });
}
