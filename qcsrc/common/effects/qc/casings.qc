#include "casings.qh"
#ifdef SVQC
void SpawnCasing(vector vel, float randomvel, vector ang, vector avel, float randomavel, int casingtype, entity casingowner, .entity weaponentity);
#endif

#ifdef IMPLEMENTATION

#include <common/util.qh>

#ifdef CSQC
#include <common/physics/movetypes/movetypes.qh>
#include "rubble.qh"
#endif

REGISTER_NET_TEMP(casings)

#ifdef SVQC
void SpawnCasing(vector vel, float randomvel, vector ang, vector avel, float randomavel, int casingtype, entity casingowner, .entity weaponentity)
{
    entity wep = casingowner.(weaponentity);
    vector org = casingowner.origin + casingowner.view_ofs + wep.spawnorigin.x * v_forward - wep.spawnorigin.y * v_right + wep.spawnorigin.z * v_up;

    if (!sound_allowed(MSG_BROADCAST, casingowner))
        casingtype |= 0x80;

    WriteHeader(MSG_ALL, casings);
    WriteByte(MSG_ALL, casingtype);
    WriteCoord(MSG_ALL, org.x);
    WriteCoord(MSG_ALL, org.y);
    WriteCoord(MSG_ALL, org.z);
    WriteShort(MSG_ALL, compressShortVector(vel)); // actually compressed velocity
    WriteByte(MSG_ALL, ang.x * 256 / 360);
    WriteByte(MSG_ALL, ang.y * 256 / 360);
    WriteByte(MSG_ALL, ang.z * 256 / 360);
}
#endif

#ifdef CSQC
entityclass(Casing);
class(Casing) .float alpha;
class(Casing) .bool silent;
class(Casing) .int state;
class(Casing) .float cnt;

void Casing_Delete(entity this)
{
    delete(this);
}

void Casing_Draw(entity this)
{
    if (IS_ONGROUND(this))
    {
        this.angles_x = 0;
        this.angles_z = 0;
        //UNSET_ONGROUND(this);
    }

    Movetype_Physics_MatchTicrate(this, autocvar_cl_casings_ticrate, autocvar_cl_casings_sloppy);
    if (wasfreed(this))
        return; // deleted by touch function

    this.renderflags = 0;
    this.alpha = bound(0, this.cnt - time, 1);

    if (this.alpha < ALPHA_MIN_VISIBLE)
    {
        Casing_Delete(this);
        this.drawmask = 0;
    }
}

SOUND(BRASS1, W_Sound("brass1"));
SOUND(BRASS2, W_Sound("brass2"));
SOUND(BRASS3, W_Sound("brass3"));
Sound SND_BRASS_RANDOM() {
    return Sounds_from(SND_BRASS1.m_id + floor(prandom() * 3));
}
SOUND(CASINGS1, W_Sound("casings1"));
SOUND(CASINGS2, W_Sound("casings2"));
SOUND(CASINGS3, W_Sound("casings3"));
Sound SND_CASINGS_RANDOM() {
    return Sounds_from(SND_CASINGS1.m_id + floor(prandom() * 3));
}

void Casing_Touch(entity this, entity toucher)
{
    if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
    {
        Casing_Delete(this);
        return;
    }

    if (!this.silent)
    if (!trace_ent || trace_ent.solid == SOLID_BSP)
    {
        if(vdist(this.velocity, >, 50))
        {
            if (time >= this.nextthink)
            {
                Sound s;
                switch (this.state)
                {
                    case 1:
                        s = SND_CASINGS_RANDOM();
                        break;
                    default:
                        s = SND_BRASS_RANDOM();
                        break;
                }

                sound (this, CH_SHOTS, s, VOL_BASE, ATTEN_LARGE);
            }
        }
    }

    this.nextthink = time + 0.2;
}

void Casing_Damage(entity this, float thisdmg, int hittype, vector org, vector thisforce)
{
    if (thisforce.z < 0)
        thisforce.z = 0;
    this.velocity = this.velocity + thisforce + '0 0 100';
    UNSET_ONGROUND(this);
}

NET_HANDLE(casings, bool isNew)
{
    int _state = ReadByte();
    vector org;
    org_x = ReadCoord();
    org_y = ReadCoord();
    org_z = ReadCoord();
    vector vel = decompressShortVector(ReadShort());
    vector ang;
    ang_x = ReadByte() * 360 / 256;
    ang_y = ReadByte() * 360 / 256;
    ang_z = ReadByte() * 360 / 256;
    return = true;

    if (!autocvar_cl_casings) return;

    Casing casing = RubbleNew("casing");
    casing.silent = (_state & 0x80);
    casing.state = (_state & 0x7F);
    casing.origin = org;
    setorigin(casing, casing.origin);
    casing.velocity = vel;
    casing.angles = ang;
    casing.drawmask = MASK_NORMAL;

    casing.draw = Casing_Draw;
    if (isNew) IL_PUSH(g_drawables, casing);
    casing.velocity = casing.velocity + 2 * prandomvec();
    casing.avelocity = '0 250 0' + 100 * prandomvec();
    set_movetype(casing, MOVETYPE_BOUNCE);
    settouch(casing, Casing_Touch);
    casing.move_time = time;
    casing.event_damage = Casing_Damage;
    casing.solid = SOLID_TRIGGER;

    switch (casing.state)
    {
        case 1:
            setmodel(casing, MDL_CASING_SHELL);
            casing.cnt = time + autocvar_cl_casings_shell_time;
            break;
        default:
            setmodel(casing, MDL_CASING_BULLET);
            casing.cnt = time + autocvar_cl_casings_bronze_time;
            break;
    }

    setsize(casing, '0 0 -1', '0 0 -1');

    RubbleLimit("casing", autocvar_cl_casings_maxcount, Casing_Delete);
}

#endif
#endif
