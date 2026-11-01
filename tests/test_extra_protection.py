"""Execute the actual multi-area gate with syntax-only C++ adaptation; no engine."""
from pathlib import Path
import random
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def method(source, signature):
    start = source.index(signature)
    opening = source.index('{', start)
    end, depth = opening + 1, 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


@unittest.skipUnless(shutil.which('g++'), 'C++ compiler required')
class ExtraProtectionTests(unittest.TestCase):
    def test_actual_position_gate_protects_union_of_areas_at_all_heights(self):
        policy = (ROOT / 'config/mission/servahz_refresh/Policy.c').read_text()
        engine = (ROOT / 'config/mission/servahz_refresh/LootRefresh.c').read_text()
        gate = method(engine, 'bool PositionProtected(')
        gate = gate.replace('ServahzLootRefreshPolicy.MayDelete', 'MayDelete').replace('m_Request.', 'm_Request->').replace('area.', 'area->')
        gate = gate.replace('foreach (ServahzProtectedArea area : m_Request->ExtraProtectedAreas)',
                            'for (ServahzProtectedArea* area : *m_Request->ExtraProtectedAreas)')
        self.assertIn('PositionProtected(descendant.GetPosition())', engine)
        self.assertIn('PositionProtected(item.GetPosition()) ||', engine)
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            cpp = folder / 'areas.cpp'
            binary = folder / ('areas.exe' if __import__('os').name == 'nt' else 'areas')
            cpp.write_text('''#include <array>
#include <vector>
#include <iostream>
using vector = std::array<float,3>;
''' + method(policy, 'static bool MayDelete(') + '''
struct ServahzProtectedArea { float CenterX, CenterZ, Radius; };
struct Request { float CenterX, CenterZ, Radius; std::vector<ServahzProtectedArea*>* ExtraProtectedAreas; };
struct Probe { Request* m_Request;
''' + gate + '''
};
int main() {
    float x,y,z; int count;
    ServahzProtectedArea a{10000,10000,1500}, b{5000,5000,700};
    while (std::cin >> x >> y >> z >> count) {
        std::vector<ServahzProtectedArea*> areas;
        if (count > 0) areas.push_back(&a);
        if (count > 1) areas.push_back(&b);
        Request request{8000,7000,500,count == 0 ? nullptr : &areas};
        Probe probe{&request};
        std::cout << probe.PositionProtected({x,y,z}) << '\\n';
    }
}
''')
            built = subprocess.run(['g++', '-std=c++11', str(cpp), '-o', str(binary)], capture_output=True, text=True)
            self.assertEqual(built.returncode, 0, built.stderr)
            rng = random.Random(18)
            points = [(8000,7000), (8500,7000), (8501,7000), (10000,10000), (11500,10000),
                      (11501,10000), (5000,5000), (5700,5000), (5701,5000)]
            points += [(rng.randrange(4000,12000), rng.randrange(4000,12000)) for _ in range(500)]
            rows, expected = [], []
            for count in range(3):
                circles = [(8000,7000,500)] + [(10000,10000,1500), (5000,5000,700)][:count]
                for x,z in points:
                    for y in [-1000,0,1000]:
                        rows.append(f'{x} {y} {z} {count}')
                        expected.append(any((x-cx)**2 + (z-cz)**2 <= r*r for cx,cz,r in circles))
            result = subprocess.run([str(binary)], input='\n'.join(rows), capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual([x == '1' for x in result.stdout.splitlines()], expected)
