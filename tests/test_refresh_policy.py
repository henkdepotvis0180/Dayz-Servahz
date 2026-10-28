"""Compile the object-free Enforce safety predicate as C++; not a DayZ engine test."""
import math
from pathlib import Path
import random
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('g++'), 'C++ compiler required for the shared numeric predicate')
class RefreshPolicyTests(unittest.TestCase):
    def test_actual_predicate_preserves_circle_inventories_and_storage(self):
        source = (ROOT / 'config/mission/servahz_refresh/Policy.c').read_text()
        start = source.index('static bool MayDelete(')
        opening = source.index('{',start)
        depth = 1
        end = opening + 1
        while depth:
            depth += (source[end] == '{') - (source[end] == '}')
            end += 1
        # These primitive types/operators have the same single-precision C++
        # representation. Execute the actual source body, without a second copy.
        predicate = source[start:end]
        with tempfile.TemporaryDirectory(prefix='servahz-policy-') as temp:
            folder = Path(temp)
            cpp = folder / 'policy.cpp'
            binary = folder / ('policy.exe' if __import__('os').name == 'nt' else 'policy')
            cpp.write_text('#include <array>\n#include <iostream>\nusing vector = std::array<float,3>;\n'+predicate+'''
int main() {
    float x,y,z,cx,cz,r; int allowed,parent,storage;
    while (std::cin >> x >> y >> z >> cx >> cz >> r >> allowed >> parent >> storage)
        std::cout << MayDelete({x,y,z},cx,cz,r,allowed,parent,storage) << '\\n';
}
''')
            built = subprocess.run(['g++','-std=c++11',str(cpp),'-o',str(binary)],capture_output=True,text=True)
            self.assertEqual(built.returncode,0,built.stderr)
            cases = []
            expected = []
            # Every floor/elevation at or inside the circle is protected.
            for x,z,result in [(8000,7000,False),(8500,7000,False),(7500,7000,False),
                               (8000,7500,False),(8330,7330,False),(8501,7000,True),(8400,7400,True)]:
                for height in [-1000,0,1000]:
                    cases.append((x,height,z,8000,7000,500,1,0,0)); expected.append(result)
            # Inventories, any cargo-capable item, and non-target classes are
            # excluded even arbitrarily far from the base.
            for allowed,parent,storage in [(0,0,0),(1,1,0),(1,0,1),(1,1,1)]:
                cases.append((100,20,100,8000,7000,500,allowed,parent,storage)); expected.append(False)
            rng = random.Random(42)
            for _ in range(500):
                x,z = rng.randrange(7300,8700),rng.randrange(6300,7700)
                cases.append((x,2000,z,8000,7000,500,1,0,0))
                expected.append(math.dist((x,z),(8000,7000)) > 500)
            checked = subprocess.run([str(binary)],input='\n'.join(' '.join(map(str,c)) for c in cases),capture_output=True,text=True,timeout=10)
            self.assertEqual(checked.returncode,0,checked.stderr)
            self.assertEqual([line == '1' for line in checked.stdout.splitlines()],expected)
