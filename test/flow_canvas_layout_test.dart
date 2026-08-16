import 'package:flow_compose/flow_compose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the component sidebar visible at desktop widths',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = FlowController()
      ..registerNode(
        const FlowNodeDefinition(
          type: 'source',
          title: 'Source',
          description: 'Test component',
        ),
      );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlowCanvas(controller: controller)),
      ),
    );

    expect(find.text('COMPONENTS'), findsOneWidget);
    expect(find.byTooltip('Components'), findsNothing);
  });

  testWidgets('connects ports by dragging from output to input',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = FlowController()
      ..registerNodes(const [
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
            FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.input),
          ],
        ),
      ]);
    final source = controller.addNode('source', const Offset(60, 140));
    final target = controller.addNode('target', const Offset(460, 140));
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlowCanvas(controller: controller)),
      ),
    );

    final sourcePort = find.byKey(ValueKey('flow-port-${source.id}-value'));
    final targetPort = find.byKey(ValueKey('flow-port-${target.id}-value'));
    final sourceCenter = tester.getCenter(sourcePort);
    final targetCenter = tester.getCenter(targetPort);
    await tester.dragFrom(sourceCenter, targetCenter - sourceCenter);
    await tester.pump();

    expect(controller.graph.edges, hasLength(1));
    expect(controller.graph.edges.single.source.nodeId, source.id);
    expect(controller.graph.edges.single.target.nodeId, target.id);
  });

  testWidgets('reconnects an edge by dragging its target handle',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = FlowController()
      ..registerNodes(const [
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
            FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.input),
          ],
        ),
      ]);
    final source = controller.addNode('source', const Offset(60, 140));
    final firstTarget = controller.addNode('target', const Offset(460, 140));
    final secondTarget = controller.addNode('target', const Offset(460, 380));
    controller.connect(
      FlowPortRef(source.id, 'value'),
      FlowPortRef(firstTarget.id, 'value'),
    );
    final edge = controller.graph.edges.single;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlowCanvas(controller: controller)),
      ),
    );

    final edgeHandle = find.byKey(ValueKey('flow-edge-target-${edge.id}'));
    final targetPort =
        find.byKey(ValueKey('flow-port-${secondTarget.id}-value'));
    final handleCenter = tester.getCenter(edgeHandle);
    final targetCenter = tester.getCenter(targetPort);
    await tester.dragFrom(handleCenter, targetCenter - handleCenter);
    await tester.pump();

    expect(controller.graph.edges, hasLength(1));
    expect(controller.graph.edges.single.id, edge.id);
    expect(controller.graph.edges.single.target.nodeId, secondTarget.id);
  });

  testWidgets('moves an edge target arrow with a node before drag ends',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = FlowController()
      ..registerNodes(const [
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
            FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.input),
          ],
        ),
      ]);
    final source = controller.addNode('source', const Offset(60, 140));
    final target = controller.addNode('target', const Offset(460, 140));
    controller.connect(
      FlowPortRef(source.id, 'value'),
      FlowPortRef(target.id, 'value'),
    );
    final edge = controller.graph.edges.single;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlowCanvas(controller: controller)),
      ),
    );

    final arrow = find.byKey(ValueKey('flow-edge-target-${edge.id}'));
    final arrowBefore = tester.getCenter(arrow);
    final header = find.byKey(ValueKey('flow-node-drag-${target.id}'));
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();

    expect(tester.getCenter(arrow).dy, closeTo(arrowBefore.dy + 80, 2));
    await gesture.up();
  });

  testWidgets('keeps the reconnect arrow with the pointer during a drag',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = FlowController()
      ..registerNodes(const [
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
            FlowPort(id: 'value', label: 'Value', kind: FlowPortKind.input),
          ],
        ),
      ]);
    final source = controller.addNode('source', const Offset(60, 140));
    final target = controller.addNode('target', const Offset(460, 140));
    controller.connect(
      FlowPortRef(source.id, 'value'),
      FlowPortRef(target.id, 'value'),
    );
    final edge = controller.graph.edges.single;
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlowCanvas(controller: controller)),
      ),
    );

    final arrow = find.byKey(ValueKey('flow-edge-target-${edge.id}'));
    final start = tester.getCenter(arrow);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-90, 70));
    await tester.pump();

    final current = tester.getCenter(arrow);
    expect(current.dx, closeTo(start.dx - 90, 2));
    expect(current.dy, closeTo(start.dy + 70, 2));
    await gesture.up();
  });
}
